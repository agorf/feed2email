require 'digest'
require 'yaml'

module Feed2Email
  class FeedMeta
    def initialize(uri)
      @uri = uri
      @dirty = false
    end

    def [](key)
      data[key]
    end

    def []=(key, value)
      @dirty = true if data[key] != value
      data[key] = value
    end

    def has_key?(key)
      data.has_key?(key)
    end

    def sync
      open(path, 'w') {|f| f.write(data.to_yaml) } if dirty
    end

    private

    def load_data
      begin
        @data = YAML.load(open(path))
      rescue Errno::ENOENT
        @data = {}
      end
    end

    def path
      @path ||= File.join(CONFIG_DIR, filename)
    end

    def filename
      "meta-#{filename_suffix}.yml"
    end

    def filename_suffix
      Digest::MD5.hexdigest(uri)
    end

    def data
      @data ||= load_data
    end

    def dirty; @dirty end

    def uri; @uri end
  end
end
