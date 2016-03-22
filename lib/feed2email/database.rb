require 'sequel'

module Feed2Email
  module Database
    def self.connection(database:, logger: nil)
      Sequel.connect(
        adapter:       'sqlite',
        database:      database,
        loggers:       Array(logger),
        sql_log_level: :debug
      )
    end

    def self.create_schema(connection)
      connection.create_table? :feeds do
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

      connection.create_table? :entries do
        primary_key :id
        foreign_key :feed_id, :feeds, null: false, index: true,
                                      on_delete: :cascade
        String :uri, null: false, unique: true
        Time :created_at
        Time :updated_at
      end
    end
  end
end
