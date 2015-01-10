require 'feed2email/config'
require 'feed2email/lazy_smtp_connection'
require 'feed2email/logger'

module Feed2Email
  CONFIG_DIR = File.expand_path('~/.feed2email')

  def self.config; @config end

  def self.logger
    @logger.logger # delegate
  end

  def self.smtp_connection; @smtp_connection end

  @config = Config.new(File.join(CONFIG_DIR, 'config.yml'))

  @logger = Logger.new(config['log_path'], config['log_level'],
                       config['log_shift_age'], config['log_shift_size'])

  @smtp_connection = LazySMTPConnection.new
end
