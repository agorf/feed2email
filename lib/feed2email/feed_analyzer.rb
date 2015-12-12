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

    # Based from
    # https://github.com/yugui/rubycommitters/blob/master/opml-generator.rb
    def type
      return unless response

      case fetcher.content_type[/[^;]+/]
      when 'text/rss', 'text/rss+xml', 'application/rss+xml',
           'application/rdf+xml', 'application/xml', 'text/xml'
        return 'rss'
      when 'text/atom', 'text/atom+xml', 'application/atom+xml'
        return 'atom'
      end

      case File.extname(path)
      when '.rdf', '.rss'
        return 'rss'
      when '.atom'
        return 'atom'
      end

      case File.basename(path)
      when 'rss.xml', 'rdf.xml'
        return 'rss'
      when 'atom.xml'
        return 'atom'
      end
    end

    private

    def fetcher
      @fetcher ||= Feed2Email::HTTPFetcher.new(url)
    end

    def response
      fetcher.response
    end

    def path
      fetcher.uri_path
    end

    attr_reader :url
  end
end
