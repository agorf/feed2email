require 'nokogiri'

module Feed2Email
  class OPMLReader
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

    attr_reader :io
  end
end
