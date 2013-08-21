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
      log :debug, "Processing entry #{uri} ..."

      if send?
        log :debug, 'Sending email...'
        to_mail.send
      else
        log :debug, 'Entry should not be sent; skipping...'
      end
    end

    def title
      @data.title
    end

    def uri
      @data.url
    end

    private

    def log(*args)
      Feed2Email::Logger.instance.log(*args)
    end

    def published_at
      @data.published
    end

    def send?
      if published_at
        log :debug, 'Entry has publication timestamp'

        if published_at.past? # respect entries published in the future
          log :debug, 'Entry published in the past'

          if published_at > @feed.fetch_time
            log :debug, 'Entry not seen before'
            return true
          else
            log :debug, 'Entry seen before'
          end
        else
          log :warn, "Entry #{uri} published in the future"
        end
      else
        log :warn, "Entry #{uri} does not have publication timestamp"
      end

      false
    end

    def to_mail
      Mail.new(self)
    end
  end
end
