require 'feed2email/feed_data_file'

module Feed2Email
  class FeedHistory < FeedDataFile
    def <<(entry_uri)
      mark_dirty
      data << entry_uri
    end

    def any?
      @old_feed ||= File.exist?(path)
    end

    def include?(entry_uri)
      data.include?(entry_uri) # delegate
    end

    private

    def data_type
      Array
    end

    def filename_prefix
      'history'
    end
  end
end
