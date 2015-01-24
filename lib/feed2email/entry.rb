require 'mail'
require 'sequel'
require 'uri'
require 'feed2email'
require 'feed2email/configurable'
require 'feed2email/core_ext'
require 'feed2email/loggable'
require 'feed2email/version'

module Feed2Email
  database.setup

  class Entry < Sequel::Model(:entries)
    plugin :timestamps

    many_to_one :feed

    class << self
      attr_accessor :last_email_sent_at
    end

    include Configurable
    include Loggable

    attr_accessor :data
    attr_accessor :feed_data
    attr_accessor :feed_uri

    def process
      unless feed.old?
        logger.debug 'Skipping new feed entry...'
        save # record as seen
        return true
      end

      if old?
        logger.debug 'Skipping old entry...'
        return true
      end

      return send_mail
    end

    private

    def apply_send_delay
      return if config['send_delay'] == 0 || config['send_method'] == 'file'

      return if last_email_sent_at.nil?

      secs_since_last_email = Time.now - last_email_sent_at
      secs_to_sleep = config['send_delay'] - secs_since_last_email

      return if secs_to_sleep <= 0

      logger.debug "Sleeping for #{secs_to_sleep} seconds..."
      sleep(secs_to_sleep)
    end

    def author; data.author end

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
        content:   content,
        published: published_line,
        title:     title.strip_html,
        uri:       uri.escape_html,
      }
    end

    def body_text
      body_html.to_markdown
    end

    def build_mail
      Mail.new.tap do |m|
        m.from      = %{"#{feed_title}" <#{config['sender']}>}
        m.to        = config['recipient']
        m.subject   = title.strip_html
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

    def content
      data.content || data.summary
    end

    def delivery_method_params
      case config['send_method']
      when 'file'
        [:file, location: config['mail_path']]
      when 'sendmail'
        [:sendmail, location: config['sendmail_path']]
      when 'smtp'
        [:smtp_connection, connection: Feed2Email.smtp_connection]
      end
    end

    def feed_title; feed_data.title end

    def last_email_sent_at; Entry.last_email_sent_at end

    def last_email_sent_at=(time)
      Entry.last_email_sent_at = time
    end

    def old?
      feed.entries_dataset.where(uri: uri).any?
    end

    def published; data.published end

    def published_line
      return nil unless author || published
      text = 'Published'
      text << " by #{author}" if author
      text << " at #{published}" if published
      text
    end

    def send_mail
      apply_send_delay

      logger.debug 'Sending new entry...'

      if build_mail.deliver!
        self.last_email_sent_at = Time.now
        save # record as seen
        return true
      end
    end

    def title
      data.title.strip
    end

    def uri
      return @uri if @uri

      @uri = data.url

      # Make relative entry URL absolute by prepending feed URL
      if @uri && @uri.start_with?('/')
        @uri = URI.join(feed_uri[%r{https?://[^/]+}], @uri)
      end

      @uri
    end
  end
end
