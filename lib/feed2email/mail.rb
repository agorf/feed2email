module Feed2Email
  class Mail
    def initialize(entry, feed_title)
      @entry = entry
      @feed_title = feed_title
    end

    def send
      if smtp_configured?
        send_with_smtp
      else
        send_with_sendmail
      end
    end

    private

    def body_html
      %{
        <html>
        <body>
        <h1><a href="%{uri}">%{title}</a></h1>
        %{content}
        <p><a href="%{uri}">%{uri}</a></p>
        <p>--<br>
        Sent by <a href="https://github.com/agorf/feed2email">feed2email
        #{VERSION}</a> at #{Time.now}</p>
        </body>
        </html>
      }.gsub(/^\s+/, '') % {
        content: @entry.content,
        title:   @entry.title.strip_html,
        uri:     @entry.uri.escape_html,
      }
    end

    def body_text
      %{
        %{title}

        %{content}

        %{uri}

        --
        Sent by feed2email #{VERSION} at #{Time.now}
      }.gsub(/^\s+/, '') % {
        content: @entry.content.strip_html,
        title:   @entry.title.strip_html,
        uri:     @entry.uri,
      }
    end

    def config
      Feed2Email.config # delegate
    end

    def mail
      ::Mail.new.tap do |m|
        m.from      = %{"#{@feed_title}" <#{config['sender']}>}
        m.to        = config['recipient']
        m.subject   = @entry.title.strip_html
        m.html_part = mail_part('text/html', body_html)
        m.text_part = mail_part('text/plain', body_text)
      end.to_s
    end

    def mail_part(content_type, body)
      part = ::Mail::Part.new
      part.content_type = "#{content_type}; charset=UTF-8"
      part.body = body
      part
    end

    def send_with_sendmail
      open("|#{sendmail_bin} #{config['recipient']}", 'w') do |f|
        f.write(mail)
      end
    end

    def send_with_smtp
      smtp = Net::SMTP.new(config['smtp_host'], config['smtp_port'])
      smtp.enable_starttls if config.fetch('smtp_tls', true)

      smtp.start(
        'localhost',
        config['smtp_user'],
        config['smtp_pass'],
        config.fetch('smtp_auth', 'login').to_sym
      ) do
        smtp.send_message(mail, config['sender'], config['recipient'])
      end
    end

    def smtp_configured?
      config['smtp_host'] &&
        config['smtp_port'] &&
        config['smtp_user'] &&
        config['smtp_pass']
    end

    def sendmail_bin
      config['sendmail_path'] || '/usr/sbin/sendmail'
    end
  end
end
