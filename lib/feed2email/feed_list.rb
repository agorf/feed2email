require 'forwardable'
require 'yaml'

module Feed2Email
  class FeedList
    class DuplicateFeedError < StandardError; end
    class MissingFeedError < StandardError; end

    extend Forwardable

    def initialize(path)
      @path = path
      @dirty = false
    end

    def_delegators :data, :size, :each, :each_with_index, :empty?

    def <<(uri)
      if index = find_feed_by_uri(uri)
        raise DuplicateFeedError, "Feed already exists at index #{index}"
      end

      mark_dirty
      data << { uri: uri, enabled: true }
    end

    def delete_at(index)
      check_missing_feed(index)
      mark_dirty
      data.delete_at(index)
    end

    def process
      require 'feed2email/feed'

      begin
        each do |meta|
          next unless meta[:enabled]

          feed = Feed.new(meta)

          if feed.process # all entries processed (no errors)
            if feed.meta[:last_modified]
              mark_dirty
              meta[:last_modified] = feed.meta[:last_modified]
            end

            if feed.meta[:etag]
              mark_dirty
              meta[:etag] = feed.meta[:etag]
            end
          end

          # Check for permanent redirection and persist
          if meta[:uri] != feed.meta[:uri]
            mark_dirty
            meta[:uri] = feed.meta[:uri]
          end
        end
      ensure
        smtp_connection.finalize
      end

      sync
    end

    def sync
      open(path, 'w') {|f| f.write(to_yaml) } if dirty?
    end

    def to_s
      justify = size.to_s.size
      each_with_index.map do |feed, i|
        '%{index}: %{disabled}%{uri}' % {
          index:    i.to_s.rjust(justify),
          disabled: feed[:enabled] ? '' : 'DISABLED ',
          uri:      feed[:uri]
        }
      end.join("\n")
    end

    def toggle(index)
      check_missing_feed(index)
      mark_dirty
      data[index][:enabled] = !data[index][:enabled]
    end

    private

    def check_missing_feed(index)
      if data[index].nil?
        raise MissingFeedError, "Feed at index #{index} does not exist"
      end
    end

    def data
      return @data if @data

      if File.exist?(path)
        @data = YAML.load(read_file)
      else
        @data = []
      end
    end

    def dirty?; @dirty end

    def find_feed_by_uri(uri)
      data.index {|feed| feed[:uri] == uri }
    end

    def mark_dirty
      @dirty = true
    end

    def path; @path end

    def read_file
      File.read(path)
    end

    def smtp_connection
      Feed2Email.smtp_connection # delegate
    end

    def to_yaml
      data.to_yaml # delegate
    end
  end
end
