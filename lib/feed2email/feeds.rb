require 'forwardable'
require 'yaml'

module Feed2Email
  class Feeds
    extend Forwardable

    class MissingFeedsError < StandardError; end
    class InvalidFeedsSyntaxError < StandardError; end
    class InvalidFeedsDataTypeError < StandardError; end

    def initialize(path)
      @path = path
      check
    end

    def_delegators :data, :size, :each

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

    def path; @path end

    def data; @data end
  end
end
