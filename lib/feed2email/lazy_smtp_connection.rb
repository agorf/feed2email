require 'net/smtp'
require 'feed2email/configurable'

module Feed2Email
  class LazySMTPConnection
    include Configurable

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

    def sendmail(*args, &block)
      connect unless connected?
      smtp.sendmail(*args, &block) # delegate
    end

    private

    def smtp
      return @smtp if @smtp
      @smtp = Net::SMTP.new(config['smtp_host'], config['smtp_port'])
      @smtp.enable_starttls if config['smtp_starttls']
      @smtp
    end
  end
end
