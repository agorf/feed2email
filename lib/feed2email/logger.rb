module Feed2Email
  class Logger
    include Singleton

    def log(severity, message)
      if config['log_path']
        logger.add(::Logger.const_get(severity.upcase), message)
      end
    end

    private

    def config
      Feed2Email::Config.instance.config
    end

    def log_to
      if config['log_path'] == true
        $stdout
      elsif config['log_path'] # truthy but not true (a path)
        File.expand_path(config['log_path'])
      end
    end

    def logger
      @logger ||= begin
        logger = ::Logger.new(log_to)

        if config['log_level']
          logger.level = ::Logger.const_get(config['log_level'].upcase)
        else
          logger.level = ::Logger::INFO
        end

        logger
      end
    end
  end
end
