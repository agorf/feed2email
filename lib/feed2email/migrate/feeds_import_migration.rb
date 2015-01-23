require 'feed2email/feed'
require 'feed2email/migrate/migration'

module Feed2Email
  module Migrate
    class FeedsImportMigration < Migration
      def apply
        applicable? && migrate
      end

      private

      def applicable?
        super && table_empty? && valid_data?
      end

      def filename
        'feeds.yml'
      end

      def migrate
        data.each do |feed|
          Feed.create(
            uri:               feed[:uri],
            enabled:           feed[:enabled],
            etag:              feed[:etag],
            last_modified:     feed[:last_modified],
            last_processed_at: Time.now
          )
        end
      end

      def table_empty?
        Feed.empty?
      end

      def valid_data?
        data.is_a?(Array) && data.all? {|d| d.is_a?(Hash) && d.has_key?(:uri) }
      end
    end
  end
end
