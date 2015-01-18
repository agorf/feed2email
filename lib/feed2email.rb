require 'pathname'
require 'feed2email/config'
require 'feed2email/database'
require 'feed2email/lazy_smtp_connection'
require 'feed2email/logger'

module Feed2Email
  def self.config
    @config ||= Config.new(root.join('config.yml').to_s)
  end

  def self.logger
    @logger ||= Logger.new(
      config['log_path'], config['log_level'], config['log_shift_age'],
      config['log_shift_size']
    ).logger
  end

  def self.root
    @root ||= Pathname.new(ENV['HOME']).join('.feed2email')
  end

  def self.smtp_connection
    @smtp_connection ||= LazySMTPConnection.new
  end

  Database.new(
    adapter:  'sqlite',
    database: root.join('feed2email.db').to_s,
    loggers:  [logger]
  )
end
