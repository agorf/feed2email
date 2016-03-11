require 'mail'
require 'sequel'
require 'uri'
require 'feed2email'
require 'feed2email/configurable'
require 'feed2email/core_ext'
require 'feed2email/email'
require 'feed2email/loggable'
require 'feed2email/version'

module Feed2Email
  class Entry < Sequel::Model(:entries)
    plugin :timestamps

    many_to_one :feed

    class << self
      attr_accessor :last_email_sent_at
    end

    include Configurable
    include Loggable

    attr_accessor :data, :feed_data

    def process
      if missing_data?
        logger.warn 'Skipping entry with missing data...'
        return false
      end

      if !feed.old? && !feed.send_existing
        logger.debug 'Skipping new feed entry...'
        save # record as seen
        return true
      end

      if old?
        logger.debug 'Skipping old entry...'
        return true
      end

      send_mail
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

    def build_mail
      Email.new(
        from:      %{"#{feed_title}" <#{config['sender']}>},
        to:        config['recipient'],
        subject:   title.strip_html,
        html_body: mail_html_body,
      )
    end

    def content
      data.content || data.summary
    end

    def feed_title; feed_data.title end

    def last_email_sent_at; Entry.last_email_sent_at end

    def last_email_sent_at=(time)
      Entry.last_email_sent_at = time
    end

    def mail_html_body
      %{
        <h1><a href="%{uri}">%{title}</a></h1>
        %{content}
        <p>%{published}</p>
        <p><a href="%{uri}">%{uri}</a></p>
      }.lstrip_lines % {
        content:   content,
        published: published_line,
        title:     title.strip_html,
        uri:       uri.escape_html,
      }
    end

    def missing_data?
      [content, feed_title, title, uri].include?(nil)
    end

    def old?
      feed.entries_dataset.where(uri: uri).any?
    end

    def published; data.published end

    def published_line
      return unless author || published
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
        true
      end
    end

    def title
      if data.title
        data.title.strip
      end
    end
  end
end
