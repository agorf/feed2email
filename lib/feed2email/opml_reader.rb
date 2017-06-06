require 'nokogiri'

module Feed2Email
  class OPMLReader
    def initialize(io)
      @io = io
    end

    def urls
      Nokogiri::XML(data).css('opml body outline').map {|outline|
        outline['xmlUrl']
      }.compact
    end

    private

    attr_reader :io

    def data
      io.read
    end
  end
end
