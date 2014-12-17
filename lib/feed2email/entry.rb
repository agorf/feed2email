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

    def process
      Mail.new(self, @feed_title).send
    end

    def title
      @data.title
    end

    def uri
      @uri ||= begin
        if @data.url && @data.url[0] == '/' # invalid entry URL is a path
          @feed_uri[%r{https?://[^/]+}] + @data.url # prepend feed URI
        else
          @data.url
        end
      end
    end
  end
end
