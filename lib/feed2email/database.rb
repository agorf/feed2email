require 'sequel'

module Feed2Email
  class Database
    def initialize(connect_options)
      @connect_options = connect_options
      set_model_database
      set_sql_log_level
      setup_schema
    end

    def connection
      @connection ||= Sequel.connect(connect_options)
    end

    private

    def connect_options; @connect_options end

    def create_table(name, &block)
      unless connection.table_exists?(name)
        connection.create_table(name, &block)
      end
    end

    def set_model_database
      Sequel::Model.db = connection
    end

    def set_sql_log_level
      connection.sql_log_level = :debug
    end

    def setup_schema
      create_table :feeds do
        primary_key :id
        String :url, null: false, unique: true
        TrueClass :enabled, null: false, default: true
        String :etag
        String :last_modified
        Time :last_processed_at
      end

      create_table :entries do
        primary_key :id
        foreign_key :feed_id, :feeds, null: false, index: true,
                                      on_delete: :cascade
        String :url, null: false, unique: true
      end
    end
  end
end
