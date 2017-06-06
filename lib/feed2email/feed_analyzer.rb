require 'feedzirra'
require 'feed2email/http_fetcher'

module Feed2Email
  class FeedAnalyzer
    def initialize(url)
      @url = url
    end

    def title
      return unless response

      Feedzirra::Feed.parse(response.body).title rescue nil
    end

    def type
      return unless response

      type_from_content_type || type_from_extname || type_from_basename
    end

    private

    attr_reader :url

    def content_type
      fetcher.content_type[/[^;]+/]
    end

    def fetcher
      @fetcher ||= HTTPFetcher.new(url)
    end

    def response
      fetcher.response
    end

    def path
      fetcher.uri_path
    end

    def type_from_basename
      case File.basename(path)
      when 'rss.xml', 'rdf.xml'
        'rss'
      when 'atom.xml'
        'atom'
      end
    end

    def type_from_content_type
      case content_type
      when 'text/rss', 'text/rss+xml', 'application/rss+xml',
           'application/rdf+xml', 'application/xml', 'text/xml'
        'rss'
      when 'text/atom', 'text/atom+xml', 'application/atom+xml'
        'atom'
      end
    end

    def type_from_extname
      case File.extname(path)
      when '.rdf', '.rss'
        'rss'
      when '.atom'
        'atom'
      end
    end
  end
end
