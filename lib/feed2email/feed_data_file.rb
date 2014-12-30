require 'digest'
require 'yaml'

module Feed2Email
  class FeedDataFile
    def initialize(uri)
      @uri = uri
      @dirty = false
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
      @path ||= File.join(CONFIG_DIR, filename)
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

    def dirty; @dirty end

    def uri; @uri end
  end
end
