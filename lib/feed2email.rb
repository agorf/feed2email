require 'logger'
require 'pathname'
require 'feed2email/config'

module Feed2Email
  def self.config
    @config ||= Config.new(config_path)
  end

  def self.config_path
    root.join('config.yml').to_s
  end

  def self.database_path
    root.join('feed2email.db').to_s
  end

  def self.logger
    return @logger if @logger

    if config['log_path'] == true
      logdev = $stdout
    elsif config['log_path'] # truthy but not true (a path)
      logdev = File.expand_path(config['log_path'])
    end

    @logger = Logger.new(logdev, config['log_shift_age'],
                         config['log_shift_size'].megabytes)
    @logger.level = Logger.const_get(config['log_level'].upcase)
    @logger
  end

  def self.root
    @root ||= Pathname.new(ENV['HOME']).join('.feed2email')
  end
end
