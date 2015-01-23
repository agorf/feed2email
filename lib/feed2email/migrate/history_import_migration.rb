require 'digest/md5'
require 'feed2email/entry'
require 'feed2email/feed'
require 'feed2email/migrate/migration'

module Feed2Email
  module Migrate
    class HistoryImportMigration < Migration
      def apply
        applicable? && migrate
      end

      private

      def applicable?
        table_empty?
      end

      def feed_history_data(feed_uri)
        YAML.load(open(feed_history_path(feed_uri)))
      end

      def feed_history_path(feed_uri)
        root.join("history-#{Digest::MD5.hexdigest(feed_uri)}.yml")
      end

      def migrate
        Feed.each do |feed|
          if feed_history_path(feed.uri).exist?
            feed_history_data(feed.uri).each do |entry_uri|
              Entry.create(feed_id: feed.id, uri: entry_uri)
            end
          end
        end
      end

      def table_empty?
        Entry.empty?
      end
    end
  end
end
