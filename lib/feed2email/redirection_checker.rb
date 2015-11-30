require "net/http"
require "uri"

module Feed2Email
  class RedirectionChecker
    attr_reader :location

    def initialize(uri)
      @uri = uri
    end

    def permanently_redirected?
      redirected? && code == '301'
    end

    private

    attr_reader :code, :uri

    def check
      parsed_uri   = URI.parse(uri)
      http         = Net::HTTP.new(parsed_uri.host, parsed_uri.port)
      http.use_ssl = (parsed_uri.scheme == "https")
      response     = http.head(parsed_uri.request_uri)
      @code        = response.code
      @location    = response["location"]
    end

    def redirected?
      check unless code

      !(code =~ /\A3\d\d\z/).nil? &&
        location != uri && # prevent redirection to the same location
        !(location =~ %r{\Ahttps?://}).nil? # ignore invalid locations
    end
  end
end
