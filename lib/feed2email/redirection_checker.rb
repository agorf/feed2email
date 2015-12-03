require "net/http"
require "uri"

module Feed2Email
  class RedirectionChecker
    attr_reader :location

    def initialize(url)
      @url = url
    end

    def permanently_redirected?
      redirected? && code == '301'
    end

    private

    attr_reader :code, :url

    def check
      uri          = URI(url)
      http         = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      response     = http.head(uri.request_uri)
      @code        = response.code
      @location    = response["location"]
    end

    def redirected?
      check unless code

      !(code =~ /\A3\d\d\z/).nil? &&
        location != url && # prevent redirection to the same location
        !(location =~ %r{\Ahttps?://}).nil? # ignore invalid locations
    end
  end
end
