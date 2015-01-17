require 'net/http'
require 'uri'

module Feed2Email
  class RedirectionChecker
    def initialize(uri)
      @uri = uri
      check
    end

    def location; @location end

    def permanently_redirected?
      redirected? && code == 301
    end

    private

    def check
      parsed_uri   = URI.parse(uri)
      http         = Net::HTTP.new(parsed_uri.host, parsed_uri.port)
      http.use_ssl = (parsed_uri.scheme == 'https')
      response     = http.head(parsed_uri.request_uri)
      @code        = response.code.to_i
      @location    = response['location']
    end

    def code; @code end

    def redirected?
      [301, 302].include?(code) &&
        location != uri && # prevent redirection to the same location
        location =~ %r{\Ahttps?://} # sanitize location
    end

    def uri; @uri end
  end
end
