require 'forwardable'
require 'thor'
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

    def_delegators :data, :size, :each, :each_with_index, :empty?, :[]

    def <<(uri)
      if index = find_feed_by_uri(uri)
        raise DuplicateFeedError, "Feed #{uri} already exists at index #{index}"
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
          processed = feed.process
          sync_feed_meta(feed.meta, meta, processed)
        end
      ensure
        smtp_connection.finalize
      end

      sync
    end

    def sync
      if dirty?
        open(path, 'w') {|f| f.write(to_yaml) } > 0
      end
    end

    def to_s
      return 'Empty feed list' if empty?

      justify = size.to_s.size
      disabled = Thor::Shell::Color.new.set_color('DISABLED', :red)

      each_with_index.map do |feed, i|
        '%{index}: %{disabled}%{uri}' % {
          index:    i.to_s.rjust(justify),
          disabled: feed[:enabled] ? '' : "#{disabled} ",
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

    def sync_feed_meta(src, dest, processed)
      if processed
        if src[:last_modified]
          mark_dirty
          dest[:last_modified] = src[:last_modified]
        end

        if src[:etag]
          mark_dirty
          dest[:etag] = src[:etag]
        end
      end

      # Check for permanent redirection and persist
      if dest[:uri] != src[:uri]
        mark_dirty
        dest[:uri] = src[:uri]
      end
    end

    def to_yaml
      data.to_yaml # delegate
    end
  end
end
