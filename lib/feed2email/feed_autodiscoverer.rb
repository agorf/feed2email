require 'nokogiri'
require 'open-uri'
require 'uri'

module Feed2Email
  class FeedAutodiscoverer
    def initialize(uri)
      @uri = uri
    end

    def content_type; @content_type end

    def feeds
      return @feeds if @feeds
      fetch
      @feeds = discoverable? ? discover : []
    end

    private

    def data; @data end

    def discover
      head = Nokogiri::HTML(data).at_css('head')

      if base = head.at_css('base[href]')
        base_uri = base['href']
      else
        base_uri = uri
      end

      head.css('link[rel=alternate]').select {|link|
        link['href'] && link['type'] =~ /\Aapplication\/(rss|atom)\+xml\z/
      }.map do |link|
        if link['href'] =~ %r{\Ahttps?://} # absolute
          uri = link['href']
        else
          uri = URI.join(base_uri, link['href']).to_s # relative
        end

        { uri: uri, content_type: link['type'] }
      end
    end

    def discoverable?
      content_type == 'text/html'
    end

    def fetch
      @data, @content_type = open(uri) {|f| [f.read, f.content_type] }
    end

    def uri; @uri end
  end
end
