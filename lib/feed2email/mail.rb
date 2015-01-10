require 'mail'
require 'feed2email/lazy_smtp_connection'
require 'feed2email/version'

module Feed2Email
  class Mail
    @smtp_connection = LazySMTPConnection.new

    def self.smtp_connection
      @smtp_connection
    end

    def self.finalize
      smtp_connection.finalize # delegate
    end

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
        <p>%{published}</p>
        <p><a href="%{uri}">%{uri}</a></p>
        <p>--<br>
        Sent by <a href="https://github.com/agorf/feed2email">feed2email
        #{VERSION}</a> at #{Time.now}</p>
        </body>
        </html>
      }.gsub(/^\s+/, '') % {
        content:   entry.content,
        published: published,
        title:     entry.title.strip_html,
        uri:       entry.uri.escape_html,
      }
    end

    def body_text
      body_html.to_markdown
    end

    def config
      Feed2Email.config # delegate
    end

    def entry; @entry end

    def feed_title; @feed_title end

    def mail
      ::Mail.new.tap do |m|
        m.from      = %{"#{feed_title}" <#{config['sender']}>}
        m.to        = config['recipient']
        m.subject   = entry.title.strip_html
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

    def published
      return nil unless entry.author || entry.published
      text = 'Published'
      text << " by #{entry.author}" if entry.author
      text << " at #{entry.published}" if entry.published
      text
    end

    def send_with_sendmail
      open("|#{config['sendmail_path']} #{config['recipient']}", 'w') do |f|
        f.write(mail)
      end
    end

    def send_with_smtp
      smtp_connection.send_message(mail, config['sender'], config['recipient'])
    end

    def smtp_configured?
      config['smtp_host'] &&
        config['smtp_port'] &&
        config['smtp_user'] &&
        config['smtp_pass']
    end

    def smtp_connection
      self.class.smtp_connection
    end
  end
end
