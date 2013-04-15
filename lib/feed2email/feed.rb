module Feed2Email
  CONFIG_DIR  = File.expand_path('~/.feed2email')
  CONFIG_FILE = File.join(CONFIG_DIR, 'config.yml')
  FEEDS_FILE  = File.join(CONFIG_DIR, 'feeds.yml')
  STATE_FILE  = File.join(CONFIG_DIR, 'state.yml')
  USER_AGENT  = "feed2email/#{VERSION}"

  class Feed
    def self.process(uri)
      Feed.new(uri).process
    end

    def self.process_all
      FileUtils.mkdir_p(CONFIG_DIR)

      $config = YAML.load(open(CONFIG_FILE)) rescue nil

      if !$config.is_a? Hash
        $stderr.puts "Error: missing or invalid config file #{CONFIG_FILE}"
        exit 1
      end

      if '%o' % (File.stat(CONFIG_FILE).mode & 0777) != '600'
        $stderr.puts "Error: invalid permissions for config file #{CONFIG_FILE}"
        exit 2
      end

      if $config['recipient'].nil?
        $stderr.puts "Error: recipient missing from config file #{CONFIG_FILE}"
        exit 3
      end

      feed_uris = YAML.load(open(FEEDS_FILE)) rescue nil

      if !feed_uris.is_a? Array
        $stderr.puts "Error: missing or invalid feeds file #{FEEDS_FILE}"
        exit 4
      end

      @@fetch_times = YAML.load(open(STATE_FILE)) rescue {}

      feed_uris.each {|uri| Feed.process(uri) }

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
