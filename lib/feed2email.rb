require 'cgi'
require 'feedzirra'
require 'fileutils'
require 'logger'
require 'mail'
require 'net/smtp'
require 'sanitize'
require 'singleton'
require 'yaml'

module Feed2Email
  CONFIG_DIR = File.expand_path('~/.feed2email')

  def self.config
    @config ||= Config.new(File.join(CONFIG_DIR, 'config.yml'))
  end

  def self.logger
    @logger ||= Logger.new(config['log_path'], config['log_level'])
  end

  def self.log(*args)
    logger.log(*args) # delegate
  end
end

require 'feed2email/config'
require 'feed2email/logger'
require 'feed2email/version'
require 'feed2email/core_ext'
require 'feed2email/mail'
require 'feed2email/entry'
require 'feed2email/feed'
require 'feed2email/feeds'
