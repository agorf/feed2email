require 'feedzirra'
require 'net/http'
require 'sequel'
require 'feed2email'
require 'feed2email/config'
require 'feed2email/configurable'
require 'feed2email/core_ext'
require 'feed2email/entry'
require 'feed2email/http_fetcher'
require 'feed2email/loggable'
require 'feed2email/redirection_checker'
require 'feed2email/version'

module Feed2Email
  class Feed < Sequel::Model(:feeds)
    plugin :timestamps

    one_to_many :entries

    subset(:enabled, enabled: true)

    def_dataset_method(:oldest_first) { order(:id) }

    include Configurable
    include Loggable

    def old?; last_processed_at end

    def process
      logger.info "Processing feed #{uri} ..."

      old_last_modified, old_etag = last_modified, etag

      return false unless fetch_and_parse

      unless processable?
        logger.warn 'Feed does not have entries'
        return
      end

      # Reset feed caching parameters unless all entries were processed. This
      # makes sure the feed will be fetched on next processing.
      unless process_entries
        self.last_modified = old_last_modified
        self.etag = old_etag
      end

      self.last_processed_at = Time.now

      save(changed: true)
    end

    def to_s
      parts = [id.to_s.rjust(3)] # align right 1-999
      parts << "\e[31mDISABLED\e[0m" unless enabled
      parts << uri
      parts.join(' ')
    end

    def toggle
      update(enabled: !enabled)
    end

    def uncache
      !cached? || update(last_modified: nil, etag: nil)
    end

    private

    def cached?
      last_modified || etag
    end

    def fetch
      logger.debug 'Fetching feed...'

      begin
        handle_redirection!

        Feed2Email::HTTPFetcher.new(uri, request_headers: fetch_headers) do |f|
          if f.response.is_a?(Net::HTTPNotModified)
            logger.info 'Feed not modified; skipping...'

            return false
          end

          self.last_modified = f.response['last-modified']
          self.etag = f.response['etag']

          return f.data
        end
      rescue => e
        logger.error 'Failed to fetch feed'
        log_exception(e)

        return false
      end
    end

    def fetch_and_parse
      if xml_data = fetch
        @parsed_feed = parse(xml_data)
        @parsed_feed && @parsed_feed.respond_to?(:entries)
      end
    end

    def fetch_headers
      headers = { 'User-Agent' => "feed2email/#{VERSION}" }

      if last_modified
        headers['If-Modified-Since'] = last_modified
      end

      if etag
        headers['If-None-Match'] = etag
      end

      headers
    end

    def handle_redirection!
      checker = RedirectionChecker.new(uri)

      if checker.permanently_redirected?
        logger.warn 'Got permanently redirected!'
        self.uri = checker.location
        logger.warn "Updated feed location to #{checker.location}"
      end
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
        log_exception(e)
        return false
      end
    end

    def parsed_entries
      parsed_feed.entries
    end

    attr_reader :parsed_feed

    def process_entries
      total = processable_entries.size
      processed = true

      processable_entries.each.with_index(1) do |parsed_entry, i|
        processed = false unless process_entry(parsed_entry, i, total)
      end

      processed
    end

    def process_entry(parsed_entry, index, total)
      entry_uri = parsed_entry.url

      # Make relative entry URL absolute by prepending feed URL
      if entry_uri && entry_uri.start_with?('/') && !entry_uri.start_with?('//')
        entry_uri = URI.join(uri[%r{https?://[^/]+}], entry_uri).to_s
      end

      entry = Entry.new(feed_id: id, uri: entry_uri)
      entry.data      = parsed_entry
      entry.feed_data = parsed_feed

      begin
        logger.info "Processing entry #{index}/#{total} #{entry_uri} ..."
        return entry.process
      rescue => e
        log_exception(e)
        return false
      end
    end

    def processable?
      processable_entries.size > 0
    end

    def processable_entries
      parsed_entries.first(config['max_entries'])
    end
  end
end
