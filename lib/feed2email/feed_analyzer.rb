require 'feedzirra'
require 'net/http'
require 'uri'

module Feed2Email
  class FeedAnalyzer
    MAX_REDIRECTS = 5

    def initialize(url)
      @url = url
    end

    def title
      return unless response

      begin
        Feedzirra::Feed.parse(response.body).title
      rescue
      end
    end

    # Based from
    # https://github.com/yugui/rubycommitters/blob/master/opml-generator.rb
    def type
      return unless response

      case response['content-type'][/[^;]+/]
      when 'text/rss', 'text/rss+xml', 'application/rss+xml',
           'application/rdf+xml', 'application/xml', 'text/xml'
        return 'rss'
      when 'text/atom', 'text/atom+xml', 'application/atom+xml'
        return 'atom'
      end

      case File.extname(uri.path)
      when '.rdf', '.rss'
        return 'rss'
      when '.atom'
        return 'atom'
      end

      case File.basename(uri.path)
      when 'rss.xml', 'rdf.xml'
        return 'rss'
      when 'atom.xml'
        return 'atom'
      end
    end

    private

    attr_reader :response, :uri, :url

    def response
      return @response unless @response.nil?

      checked_url = url
      redirects = 0

      loop do
        @uri = URI.parse(checked_url)
        http = Net::HTTP.new(@uri.host, @uri.port)
        http.use_ssl = (@uri.scheme == 'https')

        begin
          @response = http.request(Net::HTTP::Get.new(@uri.request_uri))
        rescue
          @response = false
          break
        end

        break unless @response.code =~ /\A3\d\d\z/ # redirection

        redirects += 1

        if @response['location'].nil? || redirects > MAX_REDIRECTS
          @response = false
          break
        end

        checked_url = @response['location']
      end

      @response
    end
  end
end
