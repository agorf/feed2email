require 'sequel'
require 'feed2email'
require 'feed2email/configurable'
require 'feed2email/core_ext/string_refinements'
require 'feed2email/email'
require 'feed2email/loggable'
require 'feed2email/version'

module Feed2Email
  class Entry < Sequel::Model(:entries)
    using CoreExt::StringRefinements

    plugin :timestamps

    many_to_one :feed

    class << self
      attr_accessor :last_email_sent_at
    end

    include Configurable
    include Loggable

    attr_accessor :author, :content, :published, :title, :feed_title

    def process
      if missing_data?
        logger.warn 'Skipping entry with missing data...'
        return false
      end

      if skip?
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
      return if config['send_delay'] == 0
      return if config['send_method'] == 'file'
      return if Entry.last_email_sent_at.nil?

      secs_to_sleep = calculate_secs_to_sleep

      return if secs_to_sleep == 0

      logger.debug "Sleeping for #{secs_to_sleep} seconds..."
      sleep(secs_to_sleep)
    end

    def build_mail
      Email.new(
        from:      %{"#{feed_title}" <#{config['sender']}>},
        to:        config['recipient'],
        subject:   title,
        html_body: html_body,
      )
    end

    def calculate_secs_to_sleep
      secs_since_last_email = Time.now - Entry.last_email_sent_at
      secs_to_sleep = config['send_delay'] - secs_since_last_email
      [secs_to_sleep, 0].max # ensure >= 0
    end

    def html_body
      %{
        <h1><a href="#{safe_url}">#{title}</a></h1>
        #{content}
        <p>#{published_line}</p>
        <p><a href="#{safe_url}">#{safe_url}</a></p>
      }
    end

    def missing_data?
      [content, feed_title, title, uri].include?(nil)
    end

    def old?
      feed.entries_dataset.where(uri: uri).any?
    end

    def published_line
      return unless author || published
      text = 'Published'
      text << " by #{author}" if author
      text << " at #{published}" if published
      text
    end

    def safe_url
      uri.escape_html
    end

    def send_mail
      apply_send_delay

      logger.debug 'Sending new entry...'

      if build_mail.deliver!
        Entry.last_email_sent_at = Time.now
        !save(raise_on_failure: false).nil? # record as seen
      end
    end

    def skip?
      !feed.old? && !feed.send_existing
    end
  end
end
