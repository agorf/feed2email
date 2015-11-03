require 'logger'
require 'pathname'
require 'feed2email/config'
require 'feed2email/core_ext'
require 'feed2email/database'

module Feed2Email
  class << self
    attr_accessor :smtp_connection
  end

  def self.config
    @config ||= Config.new(config_path)
  end

  def self.config_path
    root_path.join('config.yml').to_s
  end

  def self.database_path
    root_path.join('feed2email.db').to_s
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

  def self.setup_database
    Sequel::Model.db = Database.new(
      adapter:       'sqlite',
      database:      database_path,
      loggers:       [logger],
      sql_log_level: :debug
    ).connection
  end

  def self.root_path
    @root_path ||= Pathname.new(ENV["HOME"]).join(".config", "feed2email")
  end
end
