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

      type_from_content_type(fetcher.content_type[/[^;]+/]) ||
        type_from_extname(path) ||
        type_from_basename(path)
    end

    private

    def fetcher
      @fetcher ||= HTTPFetcher.new(url)
    end

    def response
      fetcher.response
    end

    def path
      fetcher.uri_path
    end

    def type_from_basename(path)
      case File.basename(path)
      when 'rss.xml', 'rdf.xml'
        'rss'
      when 'atom.xml'
        'atom'
      end
    end

    def type_from_content_type(content_type)
      case content_type
      when 'text/rss', 'text/rss+xml', 'application/rss+xml',
           'application/rdf+xml', 'application/xml', 'text/xml'
        'rss'
      when 'text/atom', 'text/atom+xml', 'application/atom+xml'
        'atom'
      end
    end

    def type_from_extname(path)
      case File.extname(path)
      when '.rdf', '.rss'
        'rss'
      when '.atom'
        'atom'
      end
    end

    attr_reader :url
  end
end
