require 'sequel'
require 'feed2email'

module Feed2Email
  class Database
    def self.setup
      new(
        adapter: 'sqlite',
        database: Feed2Email.database_path,
        loggers: [Feed2Email.logger],
        sql_log_level: :debug
      )
    end

    def initialize(connect_options)
      setup_connection(connect_options)
      setup_schema
    end

    private

    def connection; @connection end

    def setup_connection(options)
      @connection = Sequel::Model.db = Sequel.connect(options)
    end

    def setup_schema
      connection.create_table? :feeds do
        primary_key :id
        String :uri, null: false, unique: true
        TrueClass :enabled, null: false, default: true
        String :etag
        String :last_modified
        Time :last_processed_at
        Time :created_at
        Time :updated_at
      end

      connection.create_table? :entries do
        primary_key :id
        foreign_key :feed_id, :feeds, null: false, index: true,
                                      on_delete: :cascade
        String :uri, null: false, unique: true
        Time :created_at
        Time :updated_at
      end
    end

    setup
  end
end
