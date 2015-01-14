require 'feedzirra'
require 'net/http'
require 'open-uri'
require 'stringio'
require 'uri'
require 'zlib'
require 'feed2email/configurable'
require 'feed2email/core_ext'
require 'feed2email/entry'
require 'feed2email/feed_history'
require 'feed2email/feed_meta'
require 'feed2email/loggable'
require 'feed2email/version'

module Feed2Email
  class Feed
    include Configurable
    include Loggable

    attr_reader :uri

    def initialize(uri)
      @uri = uri
    end

    def process
      logger.info "Processing feed #{uri} ..."

      return unless fetch_and_parse_feed

      if entries.any?
        meta.sync if process_entries
        history.sync
      else
        logger.warn 'Feed does not have entries'
      end
    end

    private

    def apply_send_delay
      return if config['send_delay'] == 0

      return if last_email_sent_at.nil?

      secs_since_last_email = Time.now - last_email_sent_at
      secs_to_sleep = config['send_delay'] - secs_since_last_email

      return if secs_to_sleep <= 0

      logger.debug "Sleeping for #{secs_to_sleep} seconds..."
      sleep(secs_to_sleep)
    end

    def fetch_feed
      logger.debug 'Fetching feed...'

      begin
        cache_feed = !permanently_redirected?

        open(uri, fetch_feed_options(cache_feed)) do |f|
          if f.meta['last-modified'] || meta.has_key?(:last_modified)
            meta[:last_modified] = f.meta['last-modified']
          end

          if f.meta['etag'] || meta.has_key?(:etag)
            meta[:etag] = f.meta['etag']
          end

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

    def permanently_redirected?
      parsed_uri = URI.parse(uri)
      http = Net::HTTP.new(parsed_uri.host, parsed_uri.port)
      http.use_ssl = (parsed_uri.scheme == 'https')
      response = http.head(parsed_uri.request_uri)

      if response.code == '301' && response['location'] != uri &&
          response['location'] =~ %r{\Ahttps?://}
        self.uri = response['location']
        logger.warn(
          "Got permanently redirected! Updated feed location to #{uri}")
        true
      else
        false
      end
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

    def fetch_feed_options(cache_feed)
      options = {
        'User-Agent' => "feed2email/#{VERSION}",
        'Accept-Encoding' => 'gzip, deflate',
      }

      if cache_feed
        if meta[:last_modified]
          options['If-Modified-Since'] = meta[:last_modified]
        end

        if meta[:etag]
          options['If-None-Match'] = meta[:etag]
        end
      end

      options
    end

    def parse_feed(xml_data)
      logger.debug 'Parsing feed...'

      begin
        Feedzirra::Feed.parse(xml_data)
      rescue => e
        logger.error 'Failed to parse feed'
        log_exception(e)
        return false
      end
    end

    def fetch_and_parse_feed
      if xml_data = fetch_feed
        @data = parse_feed(xml_data)
      end

      @data && @data.respond_to?(:entries)
    end

    def uri=(uri)
      history.uri = uri
      meta.uri = uri
      @uri = uri
    end

    def entries
      @entries ||= data.entries.first(max_entries).map {|entry_data|
        Entry.new(entry_data, uri, title)
      }
    end

    def max_entries
      config['max_entries'].to_i
    end

    def process_entries
      logger.info "Processing #{'entry'.pluralize(entries.size, 'entries')}..."
      entries.all? {|e| process_entry(e) } # false if any entry fails
    end

    def process_entry(entry)
      logger.info "Processing entry #{entry.uri} ..."

      unless history.any?
        logger.debug 'Skipping new feed entry...'
        history << entry.uri
        return true
      end

      if history.include?(entry.uri)
        logger.debug 'Skipping old entry...'
        return true
      end

      apply_send_delay

      logger.debug 'Sending new entry...'

      begin
        mail_sent = entry.send_mail
      rescue => e
        log_exception(e)
        return false
      end

      if mail_sent
        self.last_email_sent_at = Time.now
        history << entry.uri
      end

      mail_sent
    end

    def history
      @history ||= FeedHistory.new(uri)
    end

    def meta
      @meta ||= FeedMeta.new(uri)
    end

    def last_email_sent_at
      @last_email_sent_at
    end

    def last_email_sent_at=(time)
      @last_email_sent_at = time
    end

    def log_exception(error)
      logger.error "#{error.class}: #{error.message.strip}"
      error.backtrace.each {|line| logger.debug line }
    end

    def title
      data.title # delegate
    end

    def data; @data end
  end
end
