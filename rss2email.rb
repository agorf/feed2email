# coding: utf-8
require 'cgi'
require 'feedzirra'
require 'mail'

class String
  def blank?
    self.nil? || self.strip.empty?
  end

  def escape_html
    CGI.escapeHTML(self)
  end
end

module RSS2Email
  SENDMAIL   = ENV['SENDMAIL'] || '/usr/sbin/sendmail'
  MAILTO     = ENV['MAILTO'] || ENV['USER']
  FEEDS_FILE = 'feeds.yml' # list of feed URIs to check
  CACHE_FILE = 'cache.yml' # mapping of feed fetch times
  USER_AGENT = 'rss2email.rb'

  class Feed
    def self.check(uri)
      Feed.new(uri).check
    end

    def self.check_all
      @@fetch_times = YAML.load(open(CACHE_FILE)) rescue {}
      feed_uris = YAML.load(open(FEEDS_FILE)) rescue []
      feed_uris.each {|uri| Feed.check(uri) }
      open(CACHE_FILE, 'w') {|f| f.write(@@fetch_times.to_yaml) }
    end

    def initialize(uri)
      @uri = uri
    end

    def check
      process if processable?
      sync_fetch_time if !seen_before? || fetched?
    end

    def fetch_time
      @@fetch_times[@uri]
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

    def feed_data
      @fetched_at ||= Time.now
      @feed_data ||= Feedzirra::Feed.fetch_and_parse(@uri, :user_agent =>
        USER_AGENT || Feedzirra::Feed::USER_AGENT)
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
      each_entry {|entry| entry.process if entry.processable? }
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

    def process
      email
    end

    def processable?
      new?
    end

    private

    def email
      open("|#{SENDMAIL} #{MAILTO}", 'w') do |f|
        f.write(to_mail)
      end
    end

    def mail_body
      body_data = {
        :url     => @entry_data.url.escape_html,
        :title   => @entry_data.title.escape_html,
        :content => @entry_data.content || @entry_data.summary,
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

    def mail_from
      from_data = {
        :name  => @feed.title,
        :email => @entry_data.author,
      }

      if from_data[:email].blank? || from_data[:email]['@'].nil?
        require 'socket'
        from_data[:email] = "#{ENV['USER']}@#{Socket.gethostname}"
      end

      '"%{name}" <%{email}>' % from_data
    end

    def new?
      @entry_data.published > @feed.fetch_time
    end

    def to_mail
      mail = Mail.new
      mail.from = mail_from
      mail.to = MAILTO
      mail.subject = @entry_data.title
      html_part = Mail::Part.new
      html_part.content_type = 'text/html; charset=UTF-8'
      html_part.body = mail_body
      mail.html_part = html_part
      mail
    end
  end
end

RSS2Email::Feed.check_all
