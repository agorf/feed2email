require 'digest'
require 'yaml'

module Feed2Email
  class FeedHistory
    def initialize(uri)
      @uri = uri
      @dirty = false
      @old_feed = File.exist?(path)
    end

    def <<(entry_uri)
      @dirty = true
      data << entry_uri
    end

    def old_feed?
      @old_feed
    end

    def old_entry?(entry_uri)
      old_feed? && data.include?(entry_uri)
    end

    def sync
      open(path, 'w') {|f| f.write(data.to_yaml) } if dirty
    end

    private

    def uri
      @uri
    end

    def dirty
      @dirty
    end

    def data
      return @data if @data

      if old_feed?
        @data = YAML.load(open(path))
      else
        @data = []
      end
    end

    def path
      @path ||= File.join(CONFIG_DIR, filename)
    end

    def filename
      "history-#{filename_suffix}.yml"
    end

    def filename_suffix
      Digest::MD5.hexdigest(uri)
    end
  end
end
