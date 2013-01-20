# coding: utf-8
require 'feedzirra'
require 'mail'

FEEDS_FILE = 'feeds.yml' # list of feed URIs to check
CACHE_FILE = 'cache.yml' # mapping of feed fetch times
SENDMAIL = ENV['SENDMAIL'] || '/usr/sbin/sendmail'
MAILTO = ENV['MAILTO'] || ENV['USER']

module RSS2Email
  def self.check_feeds
    Feed.fetch_times = YAML.load(open(CACHE_FILE)) rescue {}
    feed_uris = YAML.load(open(FEEDS_FILE)) rescue []
    feed_uris.each {|uri| Feed.check(uri) }
    open(CACHE_FILE, 'w') {|f| f.write(Feed.fetch_times.to_yaml) }
  end

  class Feed
    def self.check(uri)
      Feed.new(uri).check
    end

    def self.fetch_times
      @@fetch_times
    end

    def self.fetch_times=(fetch_times)
      @@fetch_times = fetch_times
    end

    def initialize(uri)
      @uri = uri
    end

    def check
      process if processable?
      sync_fetch_time
    end

    def fetch_time
      @@fetch_times[@uri]
    end

    def feed_data
      @fetched_at ||= Time.now
      @feed_data ||= Feedzirra::Feed.fetch_and_parse(@uri)
    end

    def title
      feed_data.title
    end

    private

    def each_entry
      feed_data.entries.each do |entry_data|
        yield Entry.new(entry_data, self)
      end
    end

    def fetched?
      feed_data.respond_to?(:entries)
    end

    def have_entries?
      feed_data.entries.any?
    end

    def seen_before?
      fetch_time.is_a?(Time)
    end

    def process
      each_entry {|entry| entry.process if entry.new? }
    end

    def processable?
      seen_before? && fetched? && have_entries?
    end

    def sync_fetch_time
      @@fetch_times[@uri] = @fetched_at || Time.now
    end
  end

  class Entry
    def initialize(entry_data, feed)
      @entry_data = entry_data
      @feed = feed
    end

    def new?
      @entry_data.published > @feed.fetch_time
    end

    def process
      send_as_mail(to_mail)
    end

    private

    def send_as_mail(mail)
      open("|#{SENDMAIL} #{mail.to.join(' ')}", 'w') do |f|
        f.write(mail)
      end
    end

    def to_mail
      mail = Mail.new
      mail.from = @entry_data.author if @entry_data.author
      mail.to = MAILTO
      mail.subject = "[#{@feed.title}] #{@entry_data.title}"
      html_part = Mail::Part.new
      html_part.content_type = 'text/html; charset=UTF-8'
      html_part.body = @entry_data.summary
      mail.html_part = html_part
      mail
    end
  end
end

RSS2Email.check_feeds
