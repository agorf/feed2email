require 'yaml'

module Feed2Email
  class Config
    class MissingConfigError < StandardError; end
    class InvalidConfigPermissionsError < StandardError; end
    class InvalidConfigSyntaxError < StandardError; end
    class InvalidConfigDataTypeError < StandardError; end
    class MissingConfigOptionError < StandardError; end

    attr_reader :path

    def initialize(path)
      @path = path
      check
    end

    def [](option)
      config[option] # delegate
    end

    def smtp_configured?
      config['smtp_host'] && config['smtp_port'] && config['smtp_user'] &&
        config['smtp_pass']
    end

    private

    def data
      @data
    end

    def check
      check_existence
      check_permissions
      check_syntax
      check_data_type
      check_recipient_existence
      check_sender_existence
    end

    def check_existence
      if !File.exist?(path)
        raise MissingConfigError, "Missing config file #{path}"
      end
    end

    def check_permissions
      if '%o' % (File.stat(path).mode & 0777) != '600'
        raise InvalidConfigPermissionsError,
          "Invalid permissions for config file #{path}"
      end
    end

    def check_syntax
      begin
        load_yaml
      rescue Psych::SyntaxError
        raise InvalidConfigSyntaxError,
          "Invalid YAML syntax for config file #{path}"
      end
    end

    def check_data_type
      if !data.is_a?(Hash)
        raise InvalidConfigDataTypeError,
          "Invalid data type (not a Hash) for config file #{path}"
      end
    end

    def check_recipient_existence
      check_option_existence('recipient')
    end

    def check_sender_existence
      check_option_existence('sender')
    end

    def load_yaml
      @data = YAML.load(read_file)
    end

    def read_file
      File.read(path)
    end

    def config
      @config ||= defaults.merge(data)
    end

    def defaults
      {
        'log_level'      => 'info',
        'log_path'       => true,
        'log_shift_age'  => 0,
        'log_shift_size' => 1, # megabyte
        'max_entries'    => 20,
        'send_delay'     => 10,
        'sendmail_path'  => '/usr/sbin/sendmail',
        'smtp_auth'      => 'login',
        'smtp_starttls'  => true,
      }
    end

    def check_option_existence(option)
      if data[option].nil?
        raise MissingConfigOptionError,
          "Option #{option} missing from config file #{path}"
      end
    end
  end
end
