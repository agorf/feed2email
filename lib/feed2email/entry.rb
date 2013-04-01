module Feed2Email
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
      to_mail.send if to_be_sent?
    end

    def title
      @data.title
    end

    def uri
      @data.url
    end

    private

    def published_at
      @data.published
    end

    def to_be_sent?
      published_at &&
        published_at.past? && # respect entry future pubDate
        published_at > @feed.fetch_time
    end

    def to_mail
      Mail.new(self)
    end
  end
end
