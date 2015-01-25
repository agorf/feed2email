require 'pathname'
require 'feed2email/config'
require 'feed2email/logger'

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
    @logger ||= Logger.new(
      config['log_path'], config['log_level'], config['log_shift_age'],
      config['log_shift_size']
    ).logger
  end

  def self.root
    @root ||= Pathname.new(ENV['HOME']).join('.feed2email')
  end
end
