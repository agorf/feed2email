require 'forwardable'
require 'yaml'

module Feed2Email
  class Config
    class ConfigError < StandardError; end
    class MissingConfigError < ConfigError; end
    class InvalidConfigPermissionsError < ConfigError; end
    class InvalidConfigSyntaxError < ConfigError; end
    class InvalidConfigDataTypeError < ConfigError; end
    class MissingConfigOptionError < ConfigError; end
    class InvalidConfigOptionError < ConfigError; end

    SEND_METHODS = %w{file sendmail smtp}

    extend Forwardable

    delegate [:[], :keys, :slice] => :config

    def initialize(path)
      @path = path
    end

    private

    def check_data_type
      if !data.is_a?(Hash)
        raise InvalidConfigDataTypeError,
          "Invalid data type (not a Hash) for config file #{path}"
      end
    end

    def check_existence
      if !File.exist?(path)
        raise MissingConfigError, "Missing config file #{path}"
      end
    end

    def check_file
      check_existence
      check_permissions
      check_syntax
      check_data_type
    end

    def check_option(option)
      if config[option].nil?
        raise MissingConfigOptionError,
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
      if '%o' % (File.stat(path).mode & 0777) != '600'
        raise InvalidConfigPermissionsError,
          'Invalid permissions for config file' +
          "\nTo fix it, issue: chmod 600 #{path}"
      end
    end

    def check_recipient
      check_option('recipient')
    end

    def check_send_method
      unless SEND_METHODS.include?(config['send_method'])
        raise InvalidConfigOptionError,
          "Option send_method not one of: #{SEND_METHODS.join(' ')}"
      end
    end

    def check_sender
      check_option('sender')
    end

    def check_smtp_options
      check_option('smtp_host')
      check_option('smtp_port')
      check_option('smtp_user')
      check_option('smtp_pass')
    end

    def check_syntax
      begin
        data
      rescue Psych::SyntaxError
        raise InvalidConfigSyntaxError,
          "Invalid YAML syntax for config file #{path}"
      end
    end

    def config
      return @config if @config

      begin
        check_file
        @config = defaults.merge(data)
        check_options
      rescue ConfigError => e
        abort e.message
      end

      @config
    end

    def data
      @data ||= YAML.load(File.read(path))
    end

    def defaults
      {
        'log_level'      => 'info',
        'log_path'       => true,
        'log_shift_age'  => 0,
        'log_shift_size' => 1, # megabyte
        'mail_path'      => File.join(ENV['HOME'], 'Mail'),
        'max_entries'    => 20,
        'send_delay'     => 10,
        'send_method'    => 'file',
        'sendmail_path'  => '/usr/sbin/sendmail',
        'smtp_auth'      => 'login',
        'smtp_starttls'  => true,
      }
    end

    def path; @path end
  end
end
