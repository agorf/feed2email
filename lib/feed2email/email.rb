module Feed2Email
  class Email
    include Configurable

    def initialize(options)
      @options = options
    end

    def deliver!
      build_mail.deliver!
    end

    private

    def body_html
      %{
        <html>
        <body>
        #{options.fetch(:html_body)}
        <p>--<br>
        Sent by <a href="https://github.com/agorf/feed2email">feed2email
        #{VERSION}</a> at #{Time.now}</p>
        </body>
        </html>
      }.lstrip_lines
    end

    def body_text
      body_html.to_markdown
    end

    def build_mail
      Mail.new.tap do |m|
        m.from      = options.fetch(:from)
        m.to        = options.fetch(:to)
        m.subject   = options.fetch(:subject)
        m.html_part = build_mail_part('text/html', body_html)
        m.text_part = build_mail_part('text/plain', body_text)

        m.delivery_method(*delivery_method_params)
      end
    end

    def build_mail_part(content_type, body)
      part = Mail::Part.new
      part.content_type = "#{content_type}; charset=UTF-8"
      part.body = body
      part
    end

    def delivery_method_params
      @delivery_method_params ||= case config['send_method']
      when 'file'
        [:file, location: config['mail_path']]
      when 'sendmail'
        [:sendmail, location: config['sendmail_path']]
      when 'smtp'
        [:smtp_connection, connection: Feed2Email.smtp_connection]
      end
    end

    attr_reader :options
  end
end
