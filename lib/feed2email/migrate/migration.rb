require 'fileutils'
require 'yaml'
require 'feed2email'

module Feed2Email
  module Migrate
    class Migration
      def apply
        applicable? && backup_file && migrate
      end

      private

      def applicable?
        file_exists?
      end

      def backup_file
        begin
          FileUtils.cp(path, "#{path}.bak")
          true
        rescue
          false
        end
      end

      def data
        @data ||= YAML.load(open(path))
      end

      def file_exists?
        path.exist?
      end

      def path
        root_path.join(filename)
      end

      def root_path; Feed2Email.root_path end
    end
  end
end
