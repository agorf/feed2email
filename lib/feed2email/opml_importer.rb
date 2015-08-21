require 'nokogiri'

module Feed2Email
  class OPMLImporter
    def self.import(path, remove = false)
      require 'feed2email/feed'

      feeds = open(path) {|f| new(f).feeds }

      imported = 0

      feeds.each do |uri|
        if feed = Feed[uri: uri]
          warn "Feed already exists: #{feed}"
        else
          feed = Feed.new(uri: uri)

          if feed.save(raise_on_failure: false)
            puts "Imported feed: #{feed}"
            imported += 1
          else
            warn "Failed to import feed: #{feed}"
          end
        end
      end

      if remove
        Feed.exclude(uri: uris).each do |feed|
          if feed.delete
            puts "Removed feed: #{feed}"
          else
            warn "Failed to remove feed: #{feed}"
          end
        end
      end

      imported
    end

    def initialize(io)
      @io = io
    end

    def feeds
      Nokogiri::XML(data).css('opml body outline').map {|outline|
        outline['xmlUrl']
      }.compact
    end

    private

    def data
      io.read
    end

    def io; @io end
  end
end
