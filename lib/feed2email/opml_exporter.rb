require 'net/http'
require 'nokogiri'
require 'uri'

module Feed2Email
  class OPMLExporter
    MAX_REDIRECTS = 10

    def self.export(path)
      require 'feed2email/feed'

      open(path, 'w') do |f|
        uris = Feed.select_map(:uri)

        if new(uris).export(f) > 0
          uris.size
        end
      end
    end

    def initialize(uris)
      @uris = uris
    end

    def export(io)
      io.write(xml)
    end

    private

    def builder
      Nokogiri::XML::Builder.new do |xml|
        xml.root {
          xml.opml(version: '2.0') {
            xml.head {
              xml.title 'feed2email subscriptions'
              xml.dateCreated Time.now
              xml.ownerName ENV['USER']
              xml.docs 'http://dev.opml.org/spec2.html'
            }
            xml.body {
              uris.each do |uri|
                xml.outline(text: uri, type: feed_type(uri), xmlUrl: uri)
              end
            }
          }
        }
      end
    end

    # Adjusted from
    # https://github.com/yugui/rubycommitters/blob/master/opml-generator.rb
    def feed_type(url)
      uri = nil
      redirects = 0

      loop do
        uri = URI.parse(url)

        begin
          response = Net::HTTP.start(uri.host, uri.port) {|http|
            http.head(uri.request_uri)
          }
        rescue
          break
        end

        if response.code =~ /\A3\d\d\z/
          redirects += 1
          return unless response['location'] && redirects <= MAX_REDIRECTS
          url = response['location']
          next
        end

        case response['content-type'][/[^;]+/]
        when 'text/rss', 'text/rss+xml', 'application/rss+xml',
             'application/rdf+xml', 'application/xml', 'text/xml'
          return 'rss'
        when 'text/atom', 'text/atom+xml', 'application/atom+xml'
          return 'atom'
        else
          break
        end
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
      else
        return
      end
    end

    def uris; @uris end

    def xml
      builder.to_xml
    end
  end
end
