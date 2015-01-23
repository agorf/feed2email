require 'feed2email/migrate/migration'

module Feed2Email
  module Migrate
    class ConvertFeedsMigration < Migration
      private

      def applicable?
        super && valid_data?
      end

      def filename
        'feeds.yml'
      end

      def migrate
        open(path, 'w') {|f| f.write(to_yaml) }
      end

      def to_yaml
        data.map {|uri| { uri: uri, enabled: true } }.to_yaml
      end

      def valid_data?
        data.is_a?(Array) && data.all? {|d| d.is_a?(String) }
      end
    end
  end
end
