module Feed2Email
  class Mail
    def initialize(entry)
      @entry = entry
    end

    def send
      if $config['smtp_host'] &&
          $config['smtp_port'] &&
          $config['smtp_user'] &&
          $config['smtp_pass']
        send_with_smtp
      else
        send_with_sendmail
      end
    end

    private

    def body
      body_data = {
        :uri     => @entry.uri.escape_html,
        :title   => @entry.title.escape_html,
        :content => @entry.content,
      }
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
      }.gsub(/^\s+/, '') % body_data
    end

    def from
      from_data = {
        :name  => @entry.feed.title,
        :email => from_address,
      }
      '"%{name}" <%{email}>' % from_data
    end

    def from_address
      if @entry.author && @entry.author['@']
        @entry.author
      else
        to
      end
    end

    def html_part
      part = ::Mail::Part.new
      part.content_type = 'text/html; charset=UTF-8'
      part.body = body
      part
    end

    def mail
      ::Mail.new.tap do |m|
        m.from      = from
        m.to        = to
        m.subject   = subject
        m.html_part = html_part
      end.to_s
    end

    def send_with_sendmail
      open("|#{sendmail_bin} #{to}", 'w') do |f|
        f.write(mail)
      end
    end

    def send_with_smtp
      host = $config['smtp_host']
      port = $config['smtp_port']
      user = $config['smtp_user']
      pass = $config['smtp_pass']
      tls  = $config['smtp_tls'] || $config['smtp_tls'].nil? # on by default
      auth = ($config['smtp_auth'] || 'login').to_sym # login by default

      smtp = Net::SMTP.new(host, port)
      smtp.enable_starttls if tls
      smtp.start('localhost', user, pass, auth) do
        smtp.send_message(mail, from_address, to)
      end
    end

    def sendmail_bin
      $config['sendmail_path'] || '/usr/sbin/sendmail'
    end

    def subject
      @entry.title
    end

    def to
      $config['recipient']
    end
  end
end
