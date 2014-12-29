require 'open-uri'
require 'feed2email/core_ext'
require 'feed2email/entry'
require 'feed2email/feed_history'
require 'feed2email/feeds'
require 'feedzirra'

module Feed2Email
  class Feed
    def self.config
      Feed2Email.config # delegate
    end

    def self.log(*args)
      Feed2Email.log(*args) # delegate
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
      else
        log :warn, 'Feed does not have entries'
      end
    end

    private

    def fetch_feed
      log :debug, 'Fetching feed...'

      begin
        open(uri, fetch_feed_options) {|f| f.read }
      rescue => e
        log :error, 'Failed to fetch feed'
        log_exception(e)
        return false
      end
    end

    def fetch_feed_options
      {
        'User-Agent'      => "feed2email/#{VERSION}",
        'Accept-Encoding' => 'gzip, deflate',
      }
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

    def data
      @data
    end

    def config
      Feed2Email.config
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

    def title
      data.title
    end

    def log_exception(error)
      log :error, "#{error.class}: #{error.message.strip}"
      error.backtrace.each {|line| log :debug, line }
    end
  end
end
