require 'net/smtp'

module Feed2Email
  class SMTPConnection
    def initialize(options)
      @options = options
    end

    def finalize
      smtp.finish if connected?
    end

    def sendmail(*args, &block)
      connect unless connected?
      smtp.sendmail(*args, &block) # delegate
    end

    private

    def connect
      smtp.start('localhost', options['smtp_user'], options['smtp_pass'],
                 options['smtp_auth'].to_sym)
    end

    def connected?
      smtp.started?
    end

    def options; @options end

    def smtp
      return @smtp if @smtp
      @smtp = Net::SMTP.new(options['smtp_host'], options['smtp_port'])
      @smtp.enable_starttls if options['smtp_starttls']
      @smtp
    end
  end
end
