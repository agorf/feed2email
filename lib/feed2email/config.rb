module Feed2Email
  CONFIG_DIR = File.expand_path('~/.feed2email')

  class Config
    include Singleton

    CONFIG_FILE = File.join(CONFIG_DIR, 'config.yml')

    attr_reader :config

    def read!
      @config = YAML.load(open(CONFIG_FILE)) rescue nil

      if !@config.is_a? Hash
        STDERR.puts "Error: missing or invalid config file #{CONFIG_FILE}"
        exit 1
      end

      if '%o' % (File.stat(CONFIG_FILE).mode & 0777) != '600'
        STDERR.puts "Error: invalid permissions for config file #{CONFIG_FILE}"
        exit 2
      end

      if @config['recipient'].nil?
        STDERR.puts "Error: recipient missing from config file #{CONFIG_FILE}"
        exit 3
      end
    end
  end
end
