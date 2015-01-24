require 'feedzirra'
require 'sequel'
require 'stringio'
require 'zlib'
require 'feed2email'
require 'feed2email/configurable'
require 'feed2email/core_ext'
require 'feed2email/entry'
require 'feed2email/loggable'
require 'feed2email/open-uri'
require 'feed2email/redirection_checker'
require 'feed2email/version'

module Feed2Email
  database.setup

  class Feed < Sequel::Model(:feeds)
    plugin :dirty
    plugin :timestamps

    one_to_many :entries

    subset(:enabled, enabled: true)

    def_dataset_method(:by_smallest_id) { order(:id) }

    include Configurable
    include Loggable

    def old?; last_processed_at end

    def process
      logger.info "Processing feed #{uri} ..."

      return false unless fetch_and_parse

      if processable?
        # Reset feed caching parameters unless all entries were processed. This
        # makes sure the feed will be fetched on next processing.
        unless process_entries
          self.last_modified = initial_value(:last_modified)
          self.etag = initial_value(:etag)
        end

        self.last_processed_at = Time.now

        save
      else
        logger.warn 'Feed does not have entries'
      end
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

    def decode_content(data, content_encoding)
      case content_encoding
      when 'gzip'
        gz = Zlib::GzipReader.new(StringIO.new(data))
        xml = gz.read
        gz.close
      when 'deflate'
        xml = Zlib::Inflate.inflate(data)
      else
        xml = data
      end

      xml
    end

    def fetch
      logger.debug 'Fetching feed...'

      begin
        open(uri, fetch_options) do |f|
          handle_redirection if uri != f.base_uri

          self.last_modified = f.meta['last-modified']
          self.etag = f.meta['etag']

          return decode_content(f.read, f.meta['content-encoding'])
        end
      rescue => e
        if e.is_a?(OpenURI::HTTPError) && e.message == '304 Not Modified'
          logger.info 'Feed not modified; skipping...'
        else
          logger.error 'Failed to fetch feed'
          log_exception(e)
        end

        return false
      end
    end

    def fetch_and_parse
      if xml_data = fetch
        @parsed_feed = parse(xml_data)
        @parsed_feed && @parsed_feed.respond_to?(:entries)
      end
    end

    def fetch_options
      options = {
        'User-Agent' => "feed2email/#{VERSION}",
        'Accept-Encoding' => 'gzip, deflate',
      }

      unless permanently_redirected?
        if last_modified
          options['If-Modified-Since'] = last_modified
        end

        if etag
          options['If-None-Match'] = etag
        end
      end

      options
    end

    def handle_redirection
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

    def parsed_feed; @parsed_feed end

    def permanently_redirected?
      column_changed?(:uri)
    end

    def process_entries
      total = processable_entries.size
      processed = true

      processable_entries.each_with_index do |parsed_entry, i|
        logger.info "Processing entry #{i + 1}/#{total} #{parsed_entry.url} ..."
        processed &&= process_entry(parsed_entry)
      end

      processed
    end

    def process_entry(parsed_entry)
      entry = Entry.new(feed_id: id, uri: parsed_entry.url)
      entry.data      = parsed_entry
      entry.feed_data = parsed_feed
      entry.feed_uri  = uri

      begin
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
