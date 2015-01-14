require 'mail'
require 'feed2email/configurable'
require 'feed2email/version'

module Feed2Email
  class Mail
    extend Configurable

    if config.smtp_configured?
      ::Mail::Configuration.instance.delivery_method(:smtp_connection,
        connection: Feed2Email.smtp_connection)
    else
      ::Mail::Configuration.instance.delivery_method(:sendmail,
        location: config['sendmail_path'])
    end

    include Configurable

    def initialize(entry, feed_title)
      @entry = entry
      @feed_title = feed_title
    end

    def send
      build_mail.deliver!
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

    def build_mail
      ::Mail.new.tap do |m|
        m.from      = %{"#{feed_title}" <#{config['sender']}>}
        m.to        = config['recipient']
        m.subject   = entry.title.strip_html
        m.html_part = build_mail_part('text/html', body_html)
        m.text_part = build_mail_part('text/plain', body_text)
      end
    end

    def build_mail_part(content_type, body)
      part = ::Mail::Part.new
      part.content_type = "#{content_type}; charset=UTF-8"
      part.body = body
      part
    end

    def entry; @entry end

    def feed_title; @feed_title end

    def published
      return nil unless entry.author || entry.published
      text = 'Published'
      text << " by #{entry.author}" if entry.author
      text << " at #{entry.published}" if entry.published
      text
    end
  end
end
