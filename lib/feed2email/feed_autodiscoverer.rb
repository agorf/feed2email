require 'nokogiri'
require 'uri'
require 'feed2email/http_fetcher'

module Feed2Email
  class FeedAutodiscoverer
    DiscoveredFeed = Struct.new(:url, :content_type, :title)

    def initialize(url)
      @url = url
    end

    def discoverable?
      fetcher.content_type == "text/html" && !html_head.nil?
    end

    def feeds
      return @feeds if @feeds

      return @feeds = [] unless discoverable?

      @feeds = feed_links.map {|link| build_feed_from_link(link) }
    end

    private

    attr_reader :url

    def base_uri
      @base_uri ||= if base = html_head.at_css('base[href]')
        base['href']
      else
        fetcher.url
      end
    end

    def build_feed_from_link(link)
      url = link['href']

      if link['href'] !~ %r{\Ahttps?://} # relative
        url = URI.join(base_uri, url).to_s
      end

      DiscoveredFeed.new(url, link['type'], link['title'])
    end

    def feed_links
      links.select {|link|
        link['href'] && link['type'] =~ /\Aapplication\/(rss|atom)\+xml\z/
      }
    end

    def fetcher
      @fetcher ||= HTTPFetcher.new(url)
    end

    def html_head
      @html_head ||= Nokogiri.HTML(fetcher.data).at_css("head")
    end

    def links
      html_head.css('link[rel=alternate]')
    end
  end
end
