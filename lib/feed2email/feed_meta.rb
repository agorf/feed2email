require 'feed2email/feed_data_file'

module Feed2Email
  class FeedMeta < FeedDataFile
    def [](key)
      data[key]
    end

    def []=(key, value)
      mark_dirty if data[key] != value
      data[key] = value
    end

    def has_key?(key)
      data.has_key?(key)
    end

    private

    def data_type
      Hash
    end

    def filename_prefix
      'meta'
    end
  end
end
