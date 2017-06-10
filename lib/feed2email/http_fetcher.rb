require 'net/http'
require 'uri'

module Feed2Email
  class HTTPFetcher
    class HTTPFetcherError < StandardError
      def initialize(response)
        @response = response
      end

      attr_reader :response
    end

    class MissingLocation   < HTTPFetcherError; end
    class InvalidLocation   < HTTPFetcherError; end
    class CircularRedirects < HTTPFetcherError; end
    class TooManyRedirects  < HTTPFetcherError; end

    LOCATION_REGEX = %r{\Ahttps?://}
    MAX_REDIRECTS  = 3
    REDIRECT_CODES = [301, 302, 303, 307]
    METHOD_CLASSES = { get: Net::HTTP::Get, head: Net::HTTP::Head }

    attr_accessor :headers_only, :max_redirects, :request_headers

    attr_reader :uri

    def initialize(url, request_headers: {}, max_redirects: MAX_REDIRECTS, headers_only: false)
      @followed_locations = []
      add_followed_location(url)

      @request_headers = request_headers
      @max_redirects   = max_redirects
      @headers_only    = headers_only
    end

    def content_type
      response.content_type
    end

    def data
      response.body
    end

    def etag
      response['etag']
    end

    def last_modified
      response['last-modified']
    end

    def not_modified?
      response.is_a?(Net::HTTPNotModified)
    end

    def response
      return @response if @response

      loop do
        http = build_http
        @response = http.request(build_head_request)

        unless REDIRECT_CODES.include?(@response.code.to_i)
          @response = http.request(build_get_request) unless headers_only
          break
        end

        if @response['location'].nil?
          raise MissingLocation.new(@response)
        end

        if @response['location'] !~ LOCATION_REGEX
          raise InvalidLocation.new(@response)
        end

        if followed_location?(@response['location'])
          raise CircularRedirects.new(@response)
        end

        if followed_locations.size > max_redirects
          raise TooManyRedirects.new(@response)
        end

        add_followed_location(@response['location'])
      end

      @response
    end

    def url
      uri.to_s
    end

    def url_path
      uri.path
    end

    private

    attr_reader :followed_locations

    def add_followed_location(url)
      @uri = URI.parse(url)
      followed_locations << uri.to_s
    end

    def build_get_request
      build_request(:get)
    end

    def build_head_request
      build_request(:head)
    end

    def build_http
      Net::HTTP.new(uri.host, uri.port).tap do |http|
        http.open_timeout = http.read_timeout = 30 # seconds
        http.use_ssl = (uri.scheme == 'https')
      end
    end

    def build_request(method)
      request_class(method).new(uri.request_uri).tap do |req|
        req.initialize_http_header(request_headers)
      end
    end

    def followed_location?(url)
      followed_locations.include?(URI.parse(url).to_s)
    end

    def request_class(method)
      METHOD_CLASSES.fetch(method)
    end
  end
end
