require 'cgi'
require 'feedzirra'
require 'fileutils'
require 'logger'
require 'mail'
require 'net/smtp'
require 'sanitize'
require 'singleton'
require 'yaml'

require 'feed2email/config'
require 'feed2email/logger'
require 'feed2email/version'
require 'feed2email/core_ext'
require 'feed2email/mail'
require 'feed2email/entry'
require 'feed2email/feed'

module Feed2Email
  CONFIG_DIR = File.expand_path('~/.feed2email')
  CONFIG_FILE = File.join(CONFIG_DIR, 'config.yml')

  def self.config
    @config ||= YAML.load(open(CONFIG_FILE)) rescue nil
  end

  def self.logger
    @logger ||= Feed2Email::Logger.new(config['log_path'], config['log_level'])
  end

  def self.log(*args)
    logger.log(*args) # delegate
  end
end
