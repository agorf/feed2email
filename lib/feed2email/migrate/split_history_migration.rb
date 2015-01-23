require 'digest/md5'
require 'feed2email/migrate/migration'

module Feed2Email
  module Migrate
    class SplitHistoryMigration < Migration
      private

      def applicable?
        super && pending?
      end

      def feed_history_path(feed_uri)
        root.join("history-#{Digest::MD5.hexdigest(feed_uri)}.yml")
      end

      def filename
        'history.yml'
      end

      def migrate
        data.each do |feed_uri, entries|
          open(feed_history_path(feed_uri), 'w') {|f| f.write(entries.to_yaml) }
        end
      end

      def pending?
        Dir[root.join('history-*.yml')].empty?
      end
    end
  end
end
