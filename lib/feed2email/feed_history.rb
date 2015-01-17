require 'digest/md5'
require 'yaml'

module Feed2Email
  class FeedHistory
    def initialize(uri)
      @uri = uri
      @dirty = false
    end

    def any?
      @old_feed ||= File.exist?(path)
    end

    def path
      File.join(CONFIG_DIR, filename)
    end

    def include?(entry_uri)
      data.include?(entry_uri) # delegate
    end

    def sync
      open(path, 'w') {|f| f.write(to_yaml) } if dirty
    end

    def uri=(new_uri)
      return if new_uri == uri

      data # load data if not already loaded
      remove_file
      mark_dirty
      @uri = new_uri
    end

    def <<(entry_uri)
      mark_dirty
      data << entry_uri
    end

    private

    def data
      @data ||= load_data
    end

    def dirty; @dirty end

    def filename
      "history-#{filename_suffix}.yml"
    end

    def filename_suffix
      Digest::MD5.hexdigest(uri)
    end

    def load_data
      begin
        @data = YAML.load(open(path))
      rescue Errno::ENOENT
        @data = []
      end
    end

    def mark_dirty
      @dirty = true
    end

    def remove_file
      begin
        File.unlink(path)
      rescue Errno::ENOENT
      end
    end

    def to_yaml
      data.to_yaml # delegate
    end

    def uri; @uri end
  end
end
