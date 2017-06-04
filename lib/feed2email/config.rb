require 'forwardable'
require 'yaml'

module Feed2Email
  class Config
    class ConfigError < StandardError; end
    class InvalidPermissionsError < ConfigError; end
    class InvalidSyntaxError < ConfigError; end
    class InvalidDataTypeError < ConfigError; end
    class MissingOptionError < ConfigError; end
    class InvalidOptionError < ConfigError; end

    SEND_METHODS = %w{file sendmail smtp}

    extend Forwardable

    delegate [:[], :keys, :slice] => :config

    def initialize(path)
      @path = path

      create_default_config if config_missing?
    end

    private

    def check_data_type
      if !data.is_a?(Hash)
        raise InvalidDataTypeError,
          "Invalid data type (not a Hash) for config file #{path}"
      end
    end

    def check_file
      check_permissions
      check_syntax
      check_data_type
    end

    def check_option(option)
      if config[option].nil?
        raise MissingOptionError,
          "Option #{option} missing from config file #{path}"
      end
    end

    def check_options
      check_recipient
      check_sender
      check_send_method
      check_smtp_options if config['send_method'] == 'smtp'
    end

    def check_permissions
      if File.stat(path).mode & 0777 != 0600
        raise InvalidPermissionsError,
          'Invalid permissions for config file' +
          "\nTo fix it, issue: chmod 600 #{path}"
      end
    end

    def check_recipient
      check_option('recipient')
    end

    def check_send_method
      unless SEND_METHODS.include?(config['send_method'])
        raise InvalidOptionError,
          "Option send_method not one of: #{SEND_METHODS.join(', ')}"
      end
    end

    def check_sender
      check_option('sender')
    end

    def check_smtp_option(option)
      check_option("smtp_#{option}")
    end

    def check_smtp_options
      %w{host port user pass}.each {|option| check_smtp_option(option) }
    end

    def check_syntax
      begin
        data
      rescue Psych::SyntaxError
        raise InvalidSyntaxError,
          "Invalid YAML syntax for config file #{path}"
      end
    end

    def config
      return @config if @config

      check_file
      @config = defaults.merge(data)
      check_options

      @config
    end

    def config_missing?
      !File.exist?(path)
    end

    def create_default_config
      open(path, 'w') # touch
      File.chmod(0600, path)
      open(path, 'w') {|f| f << default_config.to_yaml }
    end

    def data
      @data ||= YAML.safe_load(File.read(path))
    end

    def defaults
      {
        'log_level'       => 'info',
        'log_path'        => true,
        'log_shift_age'   => 0,
        'log_shift_size'  => 1, # megabyte
        'mail_path'       => File.join(ENV['HOME'], 'Mail'),
        'max_entries'     => 20,
        'send_delay'      => 10,
        'send_exceptions' => false,
        'send_method'     => 'file',
        'sendmail_path'   => '/usr/sbin/sendmail',
        'smtp_auth'       => 'login',
        'smtp_starttls'   => true,
      }
    end

    def default_config
      {
        'sender' => "feed2email@#{hostname}",
        'recipient' => ENV.fetch('USER') + "@#{hostname}",
      }
    end

    def hostname
      require 'socket'
      Socket.gethostname
    end

    attr_reader :path
  end
end
