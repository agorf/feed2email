require 'feed2email/feed_data_file'

module Feed2Email
  class FeedHistory < FeedDataFile
    def <<(entry_uri)
      mark_dirty
      data << entry_uri
    end

    def old_feed?
      @old_feed ||= File.exist?(path)
    end

    def old_entry?(entry_uri)
      old_feed? && data.include?(entry_uri)
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
