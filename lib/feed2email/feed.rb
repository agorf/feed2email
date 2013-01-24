module Feed2Email
  FEEDS_FILE = File.expand_path('~/.feed2email/feeds.yml')
  CACHE_FILE = File.expand_path('~/.feed2email/cache.yml')
  USER_AGENT = "feed2email/#{VERSION}"

  class Feed
    def self.process(uri)
      Feed.new(uri).process
    end

    def self.process_all
      Dir.mkdir(File.dirname(CACHE_FILE)) rescue nil

      @@fetch_times = YAML.load(open(CACHE_FILE)) rescue {}

      feed_uris = YAML.load(open(FEEDS_FILE)) rescue []
      feed_uris.each {|uri| Feed.process(uri) }

      open(CACHE_FILE, 'w') {|f| f.write(@@fetch_times.to_yaml) }
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
      @fetched_at ||= Time.now
      @data ||= Feedzirra::Feed.fetch_and_parse(@uri, :user_agent => USER_AGENT)
    end

    def entries
      data.entries
    end

    def fetched?
      data.respond_to?(:entries)
    end

    def have_entries?
      data.entries.any?
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
