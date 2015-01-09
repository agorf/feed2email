require 'feed2email/mail'

module Feed2Email
  class Entry
    def initialize(data, feed_uri, feed_title)
      @data = data
      @feed_uri = feed_uri
      @feed_title = feed_title
    end

    def author
      @data.author
    end

    def content
      @data.content || @data.summary
    end

    def published
      @data.published
    end

    def send_mail
      Mail.new(self, @feed_title).send
    end

    def title
      @data.title.strip
    end

    def uri
      return @uri if @uri

      @uri = @data.url

      # Make relative entry URL absolute by prepending feed URL
      if @uri && @uri.start_with?('/')
        @uri = @feed_uri[%r{https?://[^/]+}] + @uri
      end

      @uri
    end
  end
end
