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

    def data
      @fetched_at ||= Time.now
      @data ||= Feedzirra::Feed.fetch_and_parse(@uri, :user_agent => USER_AGENT)
    end

    def fetch_time
      @@fetch_times[@uri]
    end

    def process
      process_entries if seen_before? && fetched? && have_entries?
      sync_fetch_time if !seen_before? || fetched?
    end

    private

    def each_entry
      data.entries.each do |entry_data|
        yield Entry.new(entry_data, self)
      end
    end

    def fetched?
      data.respond_to?(:entries)
    end

    def have_entries?
      data.entries.any?
    end

    def seen_before?
      fetch_time.is_a?(Time)
    end

    def process_entries
      each_entry {|entry| entry.process }
    end

    def sync_fetch_time
      @@fetch_times[@uri] = @fetched_at || Time.now
    end
  end

  class Entry
    attr_reader :data, :feed

    def initialize(data, feed)
      @data = data
      @feed = feed
    end

    def process
      to_mail.send if new?
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
        :url     => @entry.data.url.escape_html,
        :title   => @entry.data.title.escape_html,
        :content => @entry.data.content || @entry.data.summary,
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
        :name  => @entry.feed.data.title,
        :email => @entry.data.author,
      }

      if from_data[:email].blank? || from_data[:email]['@'].nil?
        require 'socket'
        from_data[:email] = "#{ENV['USER']}@#{Socket.gethostname}"
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
      @entry.data.title
    end

    def to
      MAILTO
    end
  end
end

RSS2Email::Feed.process_all
