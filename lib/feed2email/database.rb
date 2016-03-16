require 'forwardable'
require 'sequel'

module Feed2Email
  class Database
    extend Forwardable

    delegate :create_table? => :connection

    def initialize(options)
      @options = options
      create_schema
    end

    def connection
      @connection ||= Sequel.connect(options)
    end

    private

    def create_entries_table
      create_table? :entries do
        primary_key :id
        foreign_key :feed_id, :feeds, null: false, index: true,
                                      on_delete: :cascade
        String :uri, null: false, unique: true
        Time :created_at
        Time :updated_at
      end
    end

    def create_feeds_table
      create_table? :feeds do
        primary_key :id
        String :uri, null: false, unique: true
        TrueClass :enabled, null: false, default: true
        FalseClass :send_existing, null: false, default: false
        String :etag
        String :last_modified
        Time :last_processed_at
        Time :created_at
        Time :updated_at
      end
    end

    def create_schema
      create_feeds_table
      create_entries_table
    end

    attr_reader :options
  end
end
