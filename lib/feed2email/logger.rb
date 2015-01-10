require 'logger'
require 'feed2email/core_ext'

module Feed2Email
  class Logger
    attr_reader :logger

    def initialize(log_path, log_level, log_shift_age, log_shift_size)
      @log_path = log_path
      @logger = ::Logger.new(log_to(log_path), log_shift_age,
                             log_shift_size.megabytes)
      @logger.level = ::Logger.const_get(log_level.upcase)
    end

    private

    def log_to(log_path)
      if log_path == true
        $stdout
      elsif log_path # truthy but not true (a path)
        File.expand_path(log_path)
      end
    end
  end
end
