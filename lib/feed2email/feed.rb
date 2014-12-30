require 'feedzirra'
require 'forwardable'
require 'open-uri'
require 'feed2email/core_ext'
require 'feed2email/entry'
require 'feed2email/feed_history'
require 'feed2email/feed_meta'
require 'feed2email/feeds'

module Feed2Email
  class Feed
    extend Forwardable

    class << self
      extend Forwardable

      def_delegators :Feed2Email, :config, :log
    end

    def self.process_all
      log :debug, 'Loading feed subscriptions...'
      feed_uris = Feeds.new(File.join(CONFIG_DIR, 'feeds.yml'))
      log :info, "Subscribed to #{'feed'.pluralize(feed_uris.size)}"

      feed_uris.each {|uri| new(uri).process }
    end

    attr_reader :uri

    def initialize(uri)
      @uri = uri
    end

    def process
      log :info, "Processing feed #{uri} ..."

      return unless fetch_and_parse_feed

      if entries.any?
        process_entries
        history.sync
        feed_meta.sync
      else
        log :warn, 'Feed does not have entries'
      end
    end

    private

    def fetch_feed
      log :debug, 'Fetching feed...'

      begin
        open(uri, fetch_feed_options) do |f|
          if f.meta['last-modified'] || feed_meta.has_key?(:last_modified)
            feed_meta[:last_modified] = f.meta['last-modified']
          end

          if f.meta['etag'] || feed_meta.has_key?(:etag)
            feed_meta[:etag] = f.meta['etag']
          end

          return f.read
        end
      rescue OpenURI::HTTPError => e
        if e.message == '304 Not Modified'
          log :info, 'Feed not modified; skipping...'
          return false
        end

        raise
      rescue => e
        log :error, 'Failed to fetch feed'
        log_exception(e)
        return false
      end
    end

    def fetch_feed_options
      options = {
        'User-Agent'      => "feed2email/#{VERSION}",
        'Accept-Encoding' => 'gzip, deflate',
      }

      if feed_meta[:last_modified]
        options['If-Modified-Since'] = feed_meta[:last_modified]
      end

      if feed_meta[:etag]
        options['If-None-Match'] = feed_meta[:etag]
      end

      options
    end

    def parse_feed(xml_data)
      log :debug, 'Parsing feed...'

      begin
        Feedzirra::Feed.parse(xml_data)
      rescue => e
        log :error, 'Failed to parse feed'
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

    def entries
      @entries ||= data.entries.first(max_entries).map {|entry_data|
        Entry.new(entry_data, uri, title)
      }
    end

    def log(*args)
      Feed2Email::Feed.log(*args) # delegate
    end

    def max_entries
      config['max_entries'].to_i
    end

    def process_entries
      log :info, "Processing #{'entry'.pluralize(entries.size, 'entries')}..."
      entries.each {|entry| process_entry(entry) }
    end

    def process_entry(entry)
      log :info, "Processing entry #{entry.uri} ..."

      if history.old_feed?
        if history.old_entry?(entry.uri)
          log :debug, 'Skipping old entry...'
        else
          # Sleep between entry processing to avoid Net::SMTPServerBusy errors
          if config['send_delay'] > 0
            log :debug,
              "Sleeping for #{'second'.pluralize(config['send_delay'])}"
            sleep(config['send_delay'])
          end

          log :debug, 'Sending new entry...'

          begin
            entry.send_mail
          rescue => e
            log_exception(e)
          end

          if e.nil? # no errors
            history << entry.uri
          end

          e = nil
        end
      else
        log :debug, 'Skipping new feed entry...'
        history << entry.uri
      end
    end

    def history
      @history ||= FeedHistory.new(uri)
    end

    def feed_meta
      @feed_meta ||= FeedMeta.new(uri)
    end

    def log_exception(error)
      log :error, "#{error.class}: #{error.message.strip}"
      error.backtrace.each {|line| log :debug, line }
    end

    def_delegator :data, :title, :title

    def_delegator :Feed2Email, :config, :config

    def data; @data end
  end
end
