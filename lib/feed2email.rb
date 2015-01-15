require 'feed2email/config'
require 'feed2email/feed_list'
require 'feed2email/lazy_smtp_connection'
require 'feed2email/logger'

module Feed2Email
  CONFIG_DIR = File.join(ENV['HOME'], '.feed2email')

  def self.config
    @config ||= Config.new(File.join(CONFIG_DIR, 'config.yml'))
  end

  def self.feed_list
    @feed_list ||= FeedList.new(File.join(CONFIG_DIR, 'feeds.yml'))
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
