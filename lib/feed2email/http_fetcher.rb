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
      @locations       = [url]
      @request_headers = request_headers
      @max_redirects   = max_redirects
      @headers_only    = headers_only
    end

    attr_accessor :headers_only

    attr_reader :locations

    attr_accessor :max_redirects, :request_headers

    def response
      http = resp = nil

      loop do
        http = build_http
        resp = http.request(build_head_request)

        unless REDIRECT_CODES.include?(resp.code.to_i)
          resp = http.request(build_get_request) unless headers_only
          break
        end

        raise MissingLocation if resp['location'].nil?

        raise InvalidLocation if resp['location'] !~ LOCATION_REGEX

        raise CircularRedirect if visited_location?(resp['location'])

        raise TooManyRedirects if locations.size > max_redirects

        add_location(resp['location'])
      end

      resp
    end

    def url
      locations.last
    end

    private

    def add_location(url)
      @uri = nil # invalidate cache to cause url re-parsing
      locations << url
    end

    def build_request(method)
      request = request_class(method).new(uri.request_uri)
      request.initialize_http_header(request_headers)
      request
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

    def request_class(method)
      Net::HTTP.const_get(method.capitalize)
    end

    def uri
      @uri ||= URI.parse(url)
    end

    def visited_location?(location)
      locations.map {|loc| URI.parse(loc) }.include?(URI.parse(location))
    end
  end
end
