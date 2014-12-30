require 'digest'
require 'yaml'

module Feed2Email
  class FeedHistory
    def initialize(uri)
      @uri = uri
      @dirty = false
    end

    def <<(entry_uri)
      @dirty = true
      data << entry_uri
    end

    def old_feed?
      @old_feed ||= File.exist?(path)
    end

    def old_entry?(entry_uri)
      old_feed? && data.include?(entry_uri)
    end

    def sync
      open(path, 'w') {|f| f.write(data.to_yaml) } if dirty
    end

    private

    def load_data
      begin
        @data = YAML.load(open(path))
      rescue Errno::ENOENT
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

    def data
      @data ||= load_data
    end

    def dirty; @dirty end

    def uri; @uri end
  end
end
