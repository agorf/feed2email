require 'logger'
require 'spec_helper'
require 'feed2email'
require 'feed2email/database'

describe Feed2Email::Database do
  describe '.connection' do
    subject do
      described_class.connection(database: database, logger: logger).opts
    end

    let(:database) { Feed2Email.database_path }

    let(:logger) { Logger.new($stdout) }

    it 'uses the passed adapter' do
      expect(subject[:adapter]).to eq 'sqlite'
    end

    it 'creates database at the passed path' do
      expect(subject[:database]).to eq database
    end

    it 'uses the passed logger' do
      expect(subject[:loggers]).to eq [logger]
    end

    it 'logs SQL queries at the debug level' do
      expect(subject[:sql_log_level]).to eq :debug
    end

    context 'when logger is not passed' do
      subject { described_class.connection(database: database).opts }

      it 'defaults to nil' do
        expect(subject[:loggers]).to be_empty
      end
    end
  end

  describe '.create_schema' do
    subject { described_class.create_schema(connection) }

    let(:connection) { Sequel.sqlite }

    it 'creates the feeds table' do
      expect {
        subject
      }.to change {
        connection.table_exists?(:feeds)
      }.from(false).to(true)
    end

    it 'creates the entries table' do
      expect {
        subject
      }.to change {
        connection.table_exists?(:entries)
      }.from(false).to(true)
    end

    context 'when called more than once' do
      before do
        described_class.create_schema(connection)
      end

      it 'does not blow up' do
        expect { subject }.not_to raise_error
      end
    end
  end
end
