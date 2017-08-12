module Feed2Email
  class SMTPConnectionProxy
    attr_reader :smtp

    def initialize(smtp, &start_smtp)
      @smtp = smtp
      @start_smtp = start_smtp
    end

    def method_missing(name, *args)
      start_smtp.call(smtp) unless smtp.started?
      smtp.public_send(name, *args) # delegate
    end

    private

    attr_reader :start_smtp
  end
end
