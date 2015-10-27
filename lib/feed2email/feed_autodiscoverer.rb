require 'nokogiri'
require 'uri'
require 'feed2email/open-uri'

module Feed2Email
  class FeedAutodiscoverer
    def initialize(uri)
      @uri = uri
    end

    def content_type; handle.content_type end

    def feeds
      @feeds ||= discoverable? ? discover : []
    end

    private

    def data; handle.read end

    def discover
      head = Nokogiri::HTML(data).at_css('head')

      if base = head.at_css('base[href]')
        base_uri = base['href']
      else
        base_uri = handle.base_uri.to_s
      end

      head.css('link[rel=alternate]').select {|link|
        link['href'] && link['type'] =~ /\Aapplication\/(rss|atom)\+xml\z/
      }.map do |link|
        if link['href'] =~ %r{\Ahttps?://} # absolute
          uri = link['href']
        else
          uri = URI.join(base_uri, link['href']).to_s # relative
        end

        { uri: uri, content_type: link['type'], title: link['title'] }
      end
    end

    def discoverable?
      handle.content_type == 'text/html'
    end

    def handle
      @handle ||= open(uri)
    end

    attr_reader :uri
  end
end
