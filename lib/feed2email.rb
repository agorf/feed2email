require 'fileutils'
require 'logger'
require 'mail'
require 'sequel'
require 'feed2email/config'
require 'feed2email/database'

module Feed2Email
  class << self
    attr_accessor :home_path, :smtp_connection
  end

  self.home_path = ENV['HOME']

  def self.config
    @config ||= Config.new(config_path)
  end

  def self.config_path
    File.join(root_path, 'config.yml')
  end

  def self.database_path
    File.join(root_path, 'feed2email.db')
  end

  def self.delivery_method_params
    case config['send_method']
    when 'file'
      [:file, location: config['mail_path']]
    when 'sendmail'
      [:sendmail, location: config['sendmail_path']]
    when 'smtp'
      [:smtp_connection, connection: Feed2Email.smtp_connection]
    end
  end

  def self.logger
    return @logger if @logger

    if config['log_path'] == true
      logdev = $stdout
    elsif config['log_path'] # truthy but not true (a path)
      logdev = File.expand_path(config['log_path'])
    end

    @logger = Logger.new(logdev, config['log_shift_age'],
                         config['log_shift_size'] * 1024 * 1024)
    @logger.level = Logger.const_get(config['log_level'].upcase)
    @logger
  end

  def self.root_path
    return @root_path if @root_path

    @root_path = File.join(home_path, '.config', 'feed2email')
    FileUtils.mkdir_p(@root_path)

    @root_path
  end

  def self.setup_database(connection: nil, log: false)
    connection ||= Database.connection(
      database: Feed2Email.database_path,
      logger:   log ? logger : nil
    )
    Database.create_schema(connection)
    Sequel::Model.db = connection
  end

  def self.setup_mail_defaults
    Mail.defaults do
      delivery_method(*Feed2Email.delivery_method_params)
    end
  end
end
