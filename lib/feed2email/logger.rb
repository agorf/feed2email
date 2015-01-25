require 'logger'
require 'feed2email/core_ext'

module Feed2Email
  class Logger
    attr_reader :logger

    def initialize(options)
      @options = options
      @logger = ::Logger.new(logdev, options['log_shift_age'],
                             options['log_shift_size'].megabytes)
      @logger.level = ::Logger.const_get(options['log_level'].upcase)
    end

    private

    def logdev
      if options['log_path'] == true
        $stdout
      elsif options['log_path'] # truthy but not true (a path)
        File.expand_path(options['log_path'])
      end
    end

    def options; @options end
  end
end
