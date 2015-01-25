require 'net/smtp'
require 'feed2email/configurable'

module Feed2Email
  def self.smtp_connection
    @smtp_connection
  end

  def self.smtp_connection=(smtp_connection)
    @smtp_connection = smtp_connection
  end

  class SMTPConnection
    extend Configurable

    def self.setup
      Feed2Email.smtp_connection = SMTPConnection.new(
        config.slice(*config.keys.grep(/\Asmtp_/))
      )
      at_exit { Feed2Email.smtp_connection.finish }
    end

    def initialize(options)
      @options = options
    end

    def finish
      smtp.finish if started?
    end

    def sendmail(*args, &block)
      start unless started?
      smtp.sendmail(*args, &block) # delegate
    end

    private

    def options; @options end

    def smtp
      return @smtp if @smtp
      @smtp = Net::SMTP.new(options['smtp_host'], options['smtp_port'])
      @smtp.enable_starttls if options['smtp_starttls']
      @smtp
    end

    def start
      smtp.start('localhost',
        options['smtp_user'],
        options['smtp_pass'],
        options['smtp_auth'].to_sym
      )
    end

    def started?
      smtp.started? # delegate
    end
  end
end
