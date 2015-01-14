require 'forwardable'
require 'yaml'

module Feed2Email
  class Feeds
    class MissingFeedsError < StandardError; end
    class InvalidFeedsSyntaxError < StandardError; end
    class InvalidFeedsDataTypeError < StandardError; end

    extend Forwardable

    def initialize(path)
      @path = path
      @dirty = false
      check
    end

    def_delegators :data, :size, :each_with_index

    def []=(index, uri)
      mark_dirty if data[index] != uri
      data[index] = uri
    end

    def sync
      open(path, 'w') {|f| f.write(data.to_yaml) } if dirty
    end

    private

    def check
      check_existence
      check_syntax
      check_data_type
    end

    def check_existence
      if !File.exist?(path)
        raise MissingFeedsError, "Missing feeds file #{path}"
      end
    end

    def check_syntax
      begin
        load_yaml
      rescue Psych::SyntaxError
        raise InvalidFeedsSyntaxError,
          "Invalid YAML syntax for feeds file #{path}"
      end
    end

    def check_data_type
      if !data.is_a?(Array)
        raise InvalidFeedsDataTypeError,
          "Invalid data type (not an Array) for feeds file #{path}"
      end
    end

    def load_yaml
      @data = YAML.load(read_file)
    end

    def read_file
      File.read(path)
    end

    def mark_dirty
      @dirty = true
    end

    def path; @path end

    def data; @data end

    def dirty; @dirty end
  end
end
