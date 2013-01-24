# coding: utf-8
require 'cgi'
require 'feedzirra'
require 'mail'

class String
  def escape_html
    CGI.escapeHTML(self)
  end
end

module Feed2Email
  SENDMAIL   = ENV['SENDMAIL'] || '/usr/sbin/sendmail'
  MAILTO     = ENV['MAILTO'] || ENV['USER']
  FEEDS_FILE = 'feeds.yml' # list of feed URIs to check
  CACHE_FILE = 'cache.yml' # mapping of feed fetch times
  USER_AGENT = 'feed2email'

  class Feed
    def self.process(uri)
      Feed.new(uri).process
    end

    def self.process_all
      @@fetch_times = YAML.load(open(CACHE_FILE)) rescue {}

      feed_uris = YAML.load(open(FEEDS_FILE)) rescue []
      feed_uris.each {|uri| Feed.process(uri) }

      open(CACHE_FILE, 'w') {|f| f.write(@@fetch_times.to_yaml) }
    end

    def initialize(uri)
      @uri = uri
    end

    def fetch_time
      @@fetch_times[@uri]
    end

    def process
      process_entries if seen_before? && fetched? && have_entries?
      sync_fetch_time if !seen_before? || fetched?
    end

    def title
      data.title
    end

    private

    def data
      @fetched_at ||= Time.now
      @data ||= Feedzirra::Feed.fetch_and_parse(@uri, :user_agent => USER_AGENT)
    end

    def entries
      data.entries
    end

    def fetched?
      data.respond_to?(:entries)
    end

    def have_entries?
      data.entries.any?
    end

    def process_entries
      entries.each do |entry_data|
        Entry.process(entry_data, self)
      end
    end

    def seen_before?
      fetch_time.is_a?(Time)
    end

    def sync_fetch_time
      @@fetch_times[@uri] = @fetched_at || Time.now
    end
  end

  class Entry
    attr_reader :feed

    def self.process(data, feed)
      Entry.new(data, feed).process
    end

    def initialize(data, feed)
      @data = data
      @feed = feed
    end

    def author
      @data.author
    end

    def content
      @data.content || @data.summary
    end

    def process
      to_mail.send if new?
    end

    def title
      @data.title
    end

    def url
      @data.url
    end

    private

    def new?
      @data.published > @feed.fetch_time
    end

    def to_mail
      Mail.new(self)
    end
  end

  class Mail
    def initialize(entry)
      @entry = entry
    end

    def body
      body_data = {
        :url     => @entry.url.escape_html,
        :title   => @entry.title.escape_html,
        :content => @entry.content,
      }
      %{
        <html>
        <body>
        <h1><a href="%{url}">%{title}</a></h1>
        %{content}
        <p><a href="%{url}">%{url}</a></p>
        </body>
        </html>
      }.gsub(/^\s+/, '') % body_data
    end

    def from
      from_data = {
        :name  => @entry.feed.title,
        :email => @entry.author,
      }

      if from_data[:email].nil? || from_data[:email]['@'].nil?
        from_data[:email] = to
      end

      '"%{name}" <%{email}>' % from_data
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
      end
    end

    def send
      open("|#{SENDMAIL} #{to}", 'w') do |f|
        f.write(mail)
      end
    end

    def subject
      @entry.title
    end

    def to
      MAILTO
    end
  end
end

Feed2Email::Feed.process_all
