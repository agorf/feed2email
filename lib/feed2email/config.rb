module Feed2Email
  class Config
    def self.load(config_path)
      data = YAML.load(open(config_path)) rescue nil

      if !data.is_a?(Hash)
        $stderr.puts "Error: missing or invalid config file #{config_path}"
        exit 1
      end

      if '%o' % (File.stat(config_path).mode & 0777) != '600'
        $stderr.puts "Error: invalid permissions for config file #{config_path}"
        exit 2
      end

      if data['recipient'].nil?
        $stderr.puts "Error: recipient missing from config file #{config_path}"
        exit 3
      end

      data
    end
  end
end
