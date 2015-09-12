require "net/http"
require "uri"

module Feed2Email
  class RedirectionChecker
    attr_reader :location

    def initialize(uri)
      @uri = uri
    end

    def permanently_redirected?
      redirected? && code == 301
    end

    private

    attr_reader :code, :uri

    def check
      parsed_uri   = URI.parse(uri)
      http         = Net::HTTP.new(parsed_uri.host, parsed_uri.port)
      http.use_ssl = (parsed_uri.scheme == "https")
      response     = http.head(parsed_uri.request_uri)
      @code        = response.code.to_i
      @location    = response["location"]
    end

    def redirected?
      check unless code

      [301, 302].include?(code) &&
        location != uri && # prevent redirection to the same location
        location =~ %r{\Ahttps?://} # ignore invalid locations
    end
  end
end
