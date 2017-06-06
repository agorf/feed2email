require 'nokogiri'
require 'feed2email/feed_analyzer'

module Feed2Email
  class OPMLWriter
    def initialize(urls)
      @urls = urls
    end

    def write(io)
      io.write(to_xml)
    end

    private

    attr_reader :urls

    def builder
      Nokogiri::XML::Builder.new do |xml|
        xml.root do
          xml.opml(version: '2.0') do
            xml.head do
              xml.title 'feed2email subscriptions'
              xml.dateCreated Time.now
              xml.ownerName ENV['USER']
              xml.docs 'http://dev.opml.org/spec2.html'
            end

            xml.body do
              urls.each do |url|
                feed = FeedAnalyzer.new(url)

                outline_attrs = { text: url }

                if feed.title
                  outline_attrs[:text] = feed.title
                  outline_attrs[:xmlUrl] = url
                end

                outline_attrs[:type] = feed.type if feed.type

                xml.outline(outline_attrs)
              end
            end
          end
        end
      end
    end

    def to_xml
      builder.to_xml
    end
  end
end
