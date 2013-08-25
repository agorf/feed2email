module Feed2Email
  class Feed
    FEEDS_FILE = File.join(CONFIG_DIR, 'feeds.yml')
    STATE_FILE = File.join(CONFIG_DIR, 'state.yml')

    def self.log(*args)
      Feed2Email::Logger.instance.log(*args)
    end

    def self.pluralize(n, singular, plural)
      "#{n} #{n == 1 ? singular : plural}"
    end

    def self.process(uri)
      Feed.new(uri).process
    end

    def self.process_all
      Feed2Email::Config.instance.read!

      log :debug, 'Loading feed subscriptions...'
      feed_uris = YAML.load(open(FEEDS_FILE)) rescue nil

      if !feed_uris.is_a? Array
        $stderr.puts "Error: missing or invalid feeds file #{FEEDS_FILE}"
        exit 4
      end

      log :info, "Subscribed to #{pluralize(feed_uris.size, 'feed', 'feeds')}"

      log :debug, 'Loading fetch times...'
      @@fetch_times = YAML.load(open(STATE_FILE)) rescue {}

      feed_uris.each {|uri| Feed.process(uri) }

      log :debug, 'Writing fetch times...'
      open(STATE_FILE, 'w') {|f| f.write(@@fetch_times.to_yaml) }
    end

    attr_reader :uri

    def initialize(uri)
      @uri = uri
    end

    def fetch_time
      @@fetch_times[@uri]
    end

    def pluralize(*args)
      Feed2Email::Feed.pluralize(*args) # delegate
    end

    def process
      log :info, "Processing feed #{@uri} ..."

      if seen_before?
        log :debug, 'Feed seen before'

        if fetched?
          log :debug, 'Feed is fetched'

          if have_entries?
            log :info, "Processing #{pluralize(entries.size, 'entry', 'entries')}..."

            begin
              process_entries
            rescue => e
              log :error, "#{e.class}: #{e.message.strip}"
            end
          else
            log :warn, 'Feed does not have entries'
          end
        else
          log :error, 'Feed could not be fetched'
        end
      else
        log :info, 'Feed not seen before; skipping...'
      end

      if e.nil? && (!seen_before? || fetched?)
        log :debug, 'Syncing fetch time...'
        sync_fetch_time
      end
    end

    def title
      data.title
    end

    private

    def data
      if @data.nil?
        log :debug, 'Fetching and parsing feed...'
        @data = Feedzirra::Feed.fetch_and_parse(@uri,
          :user_agent => "feed2email/#{VERSION}",
          :compress   => true
        )
        @fetched_at = Time.now
      end

      @data
    end

    def entries
      data.entries
    end

    def fetched?
      data.respond_to?(:entries)
    end

    def have_entries?
      entries.any?
    end

    def log(*args)
      Feed2Email::Feed.log(*args) # delegate
    end

    def process_entries
      entries.each do |entry_data|
        Entry.process(entry_data, self)
      end
    end

    def seen_before?
      fetch_time.is_a?(Time)
    end

    def sync_fetch_time
      @@fetch_times[@uri] = @fetched_at || Time.now
    end
  end
end
