module Feed2Email
  class Logger
    include Singleton

    def log(severity, message)
      logger.add(::Logger.const_get(severity.upcase), message) if log?
    end

    private

    def config
      Feed2Email::Config.instance.config
    end

    def log?
      log_path != false
    end

    def log_level
      config['log_level'] || 'info'
    end

    def log_path
      config['log_path']
    end

    def log_to
      if log_path.nil? || log_path == true
        STDOUT
      else
        File.expand_path(log_path)
      end
    end

    def logger
      @logger ||= ::Logger.new(log_to)
      @logger.level = ::Logger.const_get(log_level.upcase)
      @logger
    end
  end
end
