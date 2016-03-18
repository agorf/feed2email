require 'nokogiri'
require 'uri'
require 'feed2email/http_fetcher'

module Feed2Email
  class FeedAutodiscoverer
    def initialize(url)
      @url = url
    end

    def discoverable?
      fetcher.content_type == "text/html" && !html_head.nil?
    end

    def feeds
      return @feeds if @feeds

      return @feeds = [] unless discoverable?

      feed_links.map {|link| feed_hash_from_link(link) }
    end

    private

    def base_uri
      @base_uri ||= if base = html_head.at_css('base[href]')
        base['href']
      else
        fetcher.url
      end
    end

    def feed_hash_from_link(link)
      feed = {
        content_type: link['type'],
        title:        link['title'],
        uri:          link['href'],
      }

      if link['href'] !~ %r{\Ahttps?://} # relative
        feed[:uri] = URI.join(base_uri, feed[:uri]).to_s
      end

      feed
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

    attr_reader :url
  end
end
