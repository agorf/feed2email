require 'feed2email/http_fetcher'
require 'nokogiri'
require 'uri'

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

      html_head.css('link[rel=alternate]').select {|link|
        link['href'] && link['type'] =~ /\Aapplication\/(rss|atom)\+xml\z/
      }.map do |link|
        feed = { content_type: link['type'], title: link['title'] }

        feed[:uri] = if link['href'] =~ %r{\Ahttps?://} # absolute
          link['href']
        else
          URI.join(base_uri, link['href']).to_s # relative
        end

        feed
      end
    end

    private

    def base_uri
      @base_uri ||= if base = html_head.at_css('base[href]')
        base['href']
      else
        fetcher.uri.to_s
      end
    end

    def fetcher
      @fetcher ||= Feed2Email::HTTPFetcher.new(url)
    end

    def html_head
      @html_head ||= Nokogiri.HTML(fetcher.data).at_css("head")
    end

    attr_reader :url
  end
end
