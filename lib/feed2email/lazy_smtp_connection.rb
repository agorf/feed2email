require 'net/smtp'

module Feed2Email
  class LazySMTPConnection
    def config
      Feed2Email.config # delegate
    end

    def connect
      smtp.start('localhost', config['smtp_user'], config['smtp_pass'],
                 config['smtp_auth'].to_sym)
    end

    def connected?
      smtp.started?
    end

    def finalize
      smtp.finish if connected?
    end

    def send_message(*args)
      connect unless connected?
      smtp.send_message(*args)
    end

    def smtp
      return @smtp if @smtp
      @smtp = Net::SMTP.new(config['smtp_host'], config['smtp_port'])
      @smtp.enable_starttls if config['smtp_tls']
      @smtp
    end
  end
end
