require 'digest/md5'
require 'yaml'

module Feed2Email
  class FeedDataFile
    def initialize(uri)
      @uri = uri
      @dirty = false
    end

    def uri=(new_uri)
      return if new_uri == uri

      data # load data if not already loaded
      remove_file
      mark_dirty
      @uri = new_uri
    end

    def sync
      open(path, 'w') {|f| f.write(data.to_yaml) } if dirty
    end

    private

    def load_data
      begin
        @data = YAML.load(open(path))
      rescue Errno::ENOENT
        @data = data_type.new
      end
    end

    def path
      File.join(CONFIG_DIR, filename)
    end

    def filename
      "#{filename_prefix}-#{filename_suffix}.yml"
    end

    def filename_suffix
      Digest::MD5.hexdigest(uri)
    end

    def data
      @data ||= load_data
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

    def dirty; @dirty end

    def uri; @uri end
  end
end
