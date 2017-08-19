require 'feedzirra'
require 'net/http'
require 'sequel'
require 'uri'
require 'feed2email'
require 'feed2email/config'
require 'feed2email/configurable'
require 'feed2email/core_ext/string_refinements'
require 'feed2email/email'
require 'feed2email/entry'
require 'feed2email/http_fetcher'
require 'feed2email/loggable'
require 'feed2email/redirection_checker'
require 'feed2email/version'

module Feed2Email
  class Feed < Sequel::Model(:feeds)
    using CoreExt::StringRefinements

    plugin :timestamps

    one_to_many :entries

    subset(:disabled, enabled: false)
    subset(:enabled, enabled: true)

    def_dataset_method(:oldest_first) { order(:created_at) }

    include Configurable
    include Loggable

    def old?
      entries_dataset.any?
    end

    def process
      logger.info "Processing feed #{url} ..."

      old_last_modified, old_etag = last_modified, etag

      return unless fetch_and_parse

      if processable_entries.empty?
        logger.warn 'Feed does not have entries'
        return
      end

      # Restore feed caching parameters unless all entries were processed. This
      # ensures the feed will not be skipped as unchanged next time feed2email
      # runs so that entries that failed to be processed are given another
      # chance.
      unless process_entries
        self.last_modified = old_last_modified
        self.etag = old_etag
      end

      save_changes
    end

    def save_without_raising(options = {})
      save(options.merge(raise_on_failure: false))
    end

    def to_s
      return url if new?

      parts = [id.to_s.rjust(3)] # align right 1-999
      parts << 'DISABLED' unless enabled
      parts << url
      parts << "last email at #{last_email_at}" if last_email_at
      parts.join(' ')
    end

    def toggle
      update(enabled: !enabled)
    end

    def uncache
      update(last_modified: nil, etag: nil)
    end

    private

    attr_reader :parsed_feed

    def build_entry(parsed_entry)
      entry_url = fully_qualified_entry_url(parsed_entry.url)
      Entry.build_from_parsed_entry(parsed_entry, url: entry_url,
                                    feed_id: id, feed_title: parsed_feed.title)
    end

    def fetch
      logger.debug 'Fetching feed...'

      begin
        handle_redirection!

        fetcher = HTTPFetcher.new(url, request_headers: fetch_headers)

        if fetcher.not_modified?
          logger.info 'Feed not modified; skipping...'
          return false
        end

        self.last_modified = fetcher.last_modified
        self.etag = fetcher.etag

        fetcher.data
      rescue => e
        logger.error 'Failed to fetch feed'
        record_exception(e)

        false
      end
    end

    def fetch_and_parse
      if xml_data = fetch
        @parsed_feed = parse(xml_data)
        parsed_feed && parsed_feed.respond_to?(:entries)
      end
    end

    def fetch_headers
      headers = { 'User-Agent' => "feed2email/#{VERSION}" }
      headers['If-Modified-Since'] = last_modified if last_modified
      headers['If-None-Match'] = etag if etag
      headers
    end

    def fully_qualified_entry_url(entry_url_or_path)
      return if entry_url_or_path.blank?
      return entry_url_or_path unless entry_url_or_path =~ %r{\A/[^/]}

      URI.join(url[%r{https?://[^/]+}], entry_url_or_path).to_s
    end

    def handle_redirection!
      checker = RedirectionChecker.new(url)

      if checker.permanently_redirected?
        logger.warn 'Got permanently redirected!'
        self.url = checker.location
        logger.warn "Updated feed location to #{checker.location}"
      end
    end

    def last_email_at
      return unless old?
      entries_dataset.order(Sequel.desc(:created_at)).first.created_at
    end

    def log_exception(error)
      logger.error "#{error.class}: #{error.message.strip}"
      error.backtrace.each {|line| logger.debug line }
    end

    def parse(xml_data)
      logger.debug 'Parsing feed...'

      begin
        Feedzirra::Feed.parse(xml_data)
      rescue => e
        logger.error 'Failed to parse feed'
        record_exception(e)
        false
      end
    end

    def parsed_entries
      parsed_feed.entries
    end

    def process_entries
      total = processable_entries.size
      processed = true

      processable_entries.each.with_index(1) do |parsed_entry, i|
        processed = false unless process_entry(parsed_entry, i, total) # &&= won't do; see c85a6647
      end

      processed
    end

    def process_entry(parsed_entry, index, total)
      entry = build_entry(parsed_entry)

      begin
        logger.info "Processing entry #{index}/#{total} #{entry.url} ..."
        entry.process
      rescue => e
        record_exception(e)
        false
      end
    end

    def processable_entries
      if config['max_entries'] == false
        parsed_entries # unlimited
      else
        parsed_entries.first(config['max_entries'])
      end
    end

    def record_exception(error)
      log_exception(error)
      send_exception(error) if config['send_exceptions']
    end

    def save_changes
      save_without_raising(changed: true)
    end

    def send_exception(error)
      Email.new(
        from:      %{"#{parsed_feed.title}" <#{config['sender']}>},
        to:        config['recipient'],
        subject:   "#{error.class}: #{error.message.strip}",
        html_body: "<p>#{error.backtrace.join('<br>')}</p>",
      ).deliver!
    end
  end
end
