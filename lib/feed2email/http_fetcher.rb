require 'net/http'
require 'uri'

module Feed2Email
  class HTTPFetcher
    class HTTPFetcherError < StandardError; end
    class MissingLocation  < HTTPFetcherError;  end
    class InvalidLocation  < HTTPFetcherError;  end
    class CircularRedirect < HTTPFetcherError;  end
    class TooManyRedirects < HTTPFetcherError;  end

    LOCATION_REGEX = %r{\Ahttps?://}
    MAX_REDIRECTS  = 3
    REDIRECT_CODES = [301, 302, 303, 307]

    def initialize(url, request_headers: {}, max_redirects: MAX_REDIRECTS, headers_only: false)
      @followed_locations = [url]
      @request_headers    = request_headers
      @max_redirects      = max_redirects
      @headers_only       = headers_only

      yield(self) if block_given?
    end

    attr_reader :followed_locations

    attr_accessor :headers_only

    attr_accessor :max_redirects, :request_headers

    def response
      return @response if @response

      loop do
        http = build_http
        @response = http.request(build_head_request)

        unless REDIRECT_CODES.include?(@response.code.to_i)
          @response = http.request(build_get_request) unless headers_only
          break
        end

        raise MissingLocation if @response['location'].nil?

        raise InvalidLocation if @response['location'] !~ LOCATION_REGEX

        raise CircularRedirect if followed_location?(@response['location'])

        raise TooManyRedirects if followed_locations.size > max_redirects

        add_followed_location(@response['location'])
      end

      @response
    end

    def url
      followed_locations.last
    end

    private

    def add_followed_location(url)
      @uri = nil # invalidate cache to cause url re-parsing
      followed_locations << url
    end

    def build_get_request
      build_request(:get)
    end

    def build_head_request
      build_request(:head)
    end

    def build_http
      Net::HTTP.new(uri.host, uri.port).tap do |http|
        http.use_ssl = (uri.scheme == 'https')
      end
    end

    def build_request(method)
      request_class(method).new(uri.request_uri).tap do |req|
        req.initialize_http_header(request_headers)
      end
    end

    def followed_location?(location)
      followed_locations.map {|loc| URI.parse(loc) }.include?(URI.parse(location))
    end

    def request_class(method)
      Net::HTTP.const_get(method.capitalize)
    end

    def uri
      @uri ||= URI.parse(url)
    end
  end
end