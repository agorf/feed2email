require 'nokogiri'

module Feed2Email
  class OPMLImporter
    def self.import(path)
      require 'feed2email/feed'

      n = 0

      open(path) do |f|
        new(f).import do |uri|
          feed = Feed.create(uri: uri)
          puts "Imported feed: #{feed}"
          n += 1
        end
      end

      n
    end

    def initialize(io)
      @io = io
    end

    def import
      uris.each {|uri| yield uri }
    end

    private

    def data
      io.read
    end

    def io; @io end

    def uris
      Nokogiri::XML(data).css('opml body outline').map {|outline|
        outline['xmlUrl']
      }.compact
    end
  end
end
