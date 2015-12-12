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

    def initialize(url, max_redirects: MAX_REDIRECTS, headers_only: false)
      @locations     = [url]
      @max_redirects = max_redirects
      @headers_only  = headers_only
    end

    attr_reader :headers_only, :locations

    def response
      http = resp = nil

      loop do
        http = build_http
        resp = http.head(uri.request_uri)

        unless REDIRECT_CODES.include?(resp.code.to_i)
          resp = http.get(uri.request_uri) unless headers_only
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

    def build_http
      Net::HTTP.new(uri.host, uri.port).tap do |http|
        http.use_ssl = (uri.scheme == 'https')
      end
    end

    attr_reader :max_redirects

    def uri
      @uri ||= URI.parse(url)
    end

    def visited_location?(location)
      locations.map {|loc| URI.parse(loc) }.include?(URI.parse(location))
    end
  end
end
