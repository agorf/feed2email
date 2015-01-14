require 'feed2email/config'
require 'feed2email/lazy_smtp_connection'
require 'feed2email/logger'

module Feed2Email
  CONFIG_DIR = File.expand_path('~/.feed2email')

  def self.config
    @config ||= Config.new(File.join(CONFIG_DIR, 'config.yml'))
  end

  def self.logger
    @logger ||= Logger.new(
      config['log_path'], config['log_level'], config['log_shift_age'],
      config['log_shift_size']
    ).logger
  end

  def self.smtp_connection
    @smtp_connection ||= LazySMTPConnection.new
  end
end
