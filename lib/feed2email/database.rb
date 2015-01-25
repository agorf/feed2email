require 'sequel'
require 'feed2email'

module Feed2Email
  def self.database
    @database
  end

  def self.database=(database)
    @database = database
  end

  def self.database_path
    root.join('feed2email.db').to_s
  end

  class Database
    def self.setup
      return if Feed2Email.database

      Feed2Email.database = new(
        adapter:       'sqlite',
        database:      Feed2Email.database_path,
        loggers:       [Feed2Email.logger],
        sql_log_level: :debug
      )
      Feed2Email.database.setup
    end

    def initialize(connect_options)
      @connect_options = connect_options
    end

    def setup
      unless connection
        setup_connection
        setup_schema
      end
    end

    private

    def connect_options; @connect_options end

    def connection; @connection end

    def path; connect_options[:database] end

    def setup_connection
      @connection = Sequel::Model.db = Sequel.connect(connect_options)
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
  end
end
