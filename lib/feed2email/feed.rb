module Feed2Email
  class Feed
    HISTORY_FILE = File.join(CONFIG_DIR, 'history.yml')

    def self.config
      Feed2Email.config # delegate
    end

    def self.log(*args)
      Feed2Email.log(*args) # delegate
    end

    def self.process_all
      log :debug, 'Loading feed subscriptions...'
      feed_uris = Feeds.new(File.join(CONFIG_DIR, 'feeds.yml'))

      log :info, "Subscribed to #{n = feed_uris.size} feed#{n == 1 ? '' : 's'}"

      log :debug, 'Loading history...'
      @@history = YAML.load(open(HISTORY_FILE)) rescue {}

      feed_uris.each do |uri|
        log :info, "Found feed #{uri}"
        Feed.new(uri).process
      end

      log :debug, 'Writing history...'
      open(HISTORY_FILE, 'w') {|f| f.write(@@history.to_yaml) }
    end

    attr_reader :uri

    def initialize(uri)
      @uri = uri
    end

    def process
      if fetched?
        log :debug, 'Feed is fetched'

        if entries.any?
          log :info,
            "Processing #{n = entries.size} entr#{n == 1 ? 'y' : 'ies'}..."
          process_entries
        else
          log :warn, 'Feed does not have entries'
        end
      else
        log :error, 'Feed could not be fetched'
      end
    end

    private

    def data
      if @data.nil?
        log :debug, 'Fetching and parsing feed...'

        begin
          @data = Feedzirra::Feed.fetch_and_parse(uri,
            :user_agent => "feed2email/#{VERSION}",
            :compress   => true
          )
        rescue => e
          log :error, "#{e.class}: #{e.message.strip}"
          e.backtrace.each {|line| log :debug, line }
        end
      end

      @data
    end

    def config
      Feed2Email.config
    end

    def entries
      @entries ||= data.entries[0..max_entries - 1].map {|entry_data|
        Entry.new(entry_data, uri, title)
      }
    end

    def fetched?
      data.respond_to?(:entries)
    end

    def log(*args)
      Feed2Email::Feed.log(*args) # delegate
    end

    def max_entries
      config['max_entries'].to_i
    end

    def process_entries
      entries.each_with_index do |entry, i|
        # Sleep between entry processing to avoid Net::SMTPServerBusy errors
        sleep(config['send_delay']) if i > 0

        log :info, "Found entry #{entry.uri}"

        if seen_before?
          if seen_entries.include?(entry.uri)
            log :debug, 'Skipping seen entry...'
          else
            log :debug, 'Processing new entry...'

            begin
              entry.process
            rescue => e
              log :error, "#{e.class}: #{e.message.strip}"
              e.backtrace.each {|line| log :debug, line }
            end

            seen_entries << entry.uri if e.nil? # record in history if no errors
            e = nil
          end
        else
          log :debug, 'Skipping new entry...'
          seen_entries << entry.uri # record in history
        end
      end
    end

    def seen_before?
      if @seen_before.nil?
        @seen_before = !@@history[uri].nil?
      end

      @seen_before
    end

    def seen_entries
      @@history[uri] ||= []
    end

    def title
      data.title
    end
  end
end
