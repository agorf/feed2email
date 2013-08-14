module Feed2Email
  class Feed
    FEEDS_FILE = File.join(CONFIG_DIR, 'feeds.yml')
    STATE_FILE = File.join(CONFIG_DIR, 'state.yml')

    def self.process(uri)
      Feed.new(uri).process
    end

    def self.process_all
      Feed2Email::Config.instance.read!

      feed_uris = YAML.load(open(FEEDS_FILE)) rescue nil

      if !feed_uris.is_a? Array
        $stderr.puts "Error: missing or invalid feeds file #{FEEDS_FILE}"
        exit 4
      end

      @@fetch_times = YAML.load(open(STATE_FILE)) rescue {}

      feed_uris.each do |uri|
        begin
          Feed.process(uri)
        rescue
          # TODO log failure
        end
      end

      open(STATE_FILE, 'w') {|f| f.write(@@fetch_times.to_yaml) }
    end

    def initialize(uri)
      @uri = uri
    end

    def fetch_time
      @@fetch_times[@uri]
    end

    def process
      process_entries if seen_before? && fetched? && have_entries?
      sync_fetch_time if !seen_before? || fetched?
    end

    def title
      data.title
    end

    private

    def data
      if @data.nil?
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
