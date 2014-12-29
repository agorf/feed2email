require 'digest'
require 'yaml'

module Feed2Email
  class FeedMeta
    def initialize(uri)
      @uri = uri
      @data = nil
      @dirty = false
    end

    def [](key)
      load_data unless data
      data[key]
    end

    def []=(key, value)
      @dirty ||= (data[key] != value)
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
      if File.exist?(path)
        @data = YAML.load(open(path))
      else
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

    def data; @data end

    def dirty; @dirty end

    def uri; @uri end
  end
end
