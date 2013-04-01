module Feed2Email
  FEEDS_FILE = File.expand_path('~/.feed2email/feeds.yml')
  CACHE_FILE = File.expand_path('~/.feed2email/cache.yml')
  USER_AGENT = "feed2email/#{VERSION}"

  class Feed
    def self.process(uri, options)
      Feed.new(uri, options).process
    end

    def self.process_all(options)
      FileUtils.mkdir_p(File.dirname(CACHE_FILE)) rescue nil

      @@fetch_times = YAML.load(open(CACHE_FILE)) rescue {}

      feed_uris = YAML.load(open(FEEDS_FILE)) rescue []
      feed_uris.each {|uri| Feed.process(uri, options) }

      open(CACHE_FILE, 'w') {|f| f.write(@@fetch_times.to_yaml) }
    end

    attr_reader :options

    def initialize(uri, options)
      @uri = uri
      @options = options
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
      fetch_opts = { :user_agent => USER_AGENT, :compress => true }
      @data ||= Feedzirra::Feed.fetch_and_parse(@uri, fetch_opts)
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
