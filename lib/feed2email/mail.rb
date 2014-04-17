module Feed2Email
  class Mail
    def initialize(entry, feed_title)
      @entry = entry
      @feed_title = feed_title
    end

    def send
      sleep config['send_delay'] || 10 # avoid Net::SMTPServerBusy errors

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
        :uri     => @entry.uri.escape_html,
        :title   => @entry.title.strip_html,
        :content => @entry.content,
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
        :title   => @entry.title.strip_html,
        :content => @entry.content.strip_html,
        :uri     => @entry.uri,
      }
    end

    def config
      Feed2Email::Config.instance.config
    end

    def from
      %{"#{@feed_title}" <#{from_address}>}
    end

    def from_address
      if config['sender']
        config['sender']
      elsif @entry.author && @entry.author['@']
        @entry.author[/\S+@\S+/]
      elsif smtp_configured?
        '%{user}@%{host}' % {
          :user => config['smtp_user'].gsub(/\W/, '_'),
          :host => config['smtp_host']
        }
      else
        to # recipient as a last resort
      end
    end

    def mail
      ::Mail.new.tap do |m|
        m.from      = from
        m.to        = to
        m.subject   = subject
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
      open("|#{sendmail_bin} #{to}", 'w') do |f|
        f.write(mail)
      end
    end

    def send_with_smtp
      host = config['smtp_host']
      port = config['smtp_port']
      user = config['smtp_user']
      pass = config['smtp_pass']
      tls  = config['smtp_tls'].nil? ? true : config['smtp_tls'] # default: true
      auth = (config['smtp_auth'] || 'login').to_sym # default: 'login'

      smtp = Net::SMTP.new(host, port)
      smtp.enable_starttls if tls
      smtp.start('localhost', user, pass, auth) do
        smtp.send_message(mail, from_address, to)
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

    def subject
      @entry.title.strip_html
    end

    def to
      config['recipient']
    end
  end
end
