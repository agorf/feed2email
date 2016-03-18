require 'simplecov'
SimpleCov.start

require 'pry'
require 'webmock/rspec'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  config.around(:each) do |example|
    Sequel::Model.db.transaction(rollback: :always, auto_savepoint: true) do
      example.run
    end
  end
end

def capture_stdout(&block)
  original_stdout = $stdout
  $stdout = fake = StringIO.new

  begin
    yield
  ensure
    $stdout = original_stdout
  end

  fake.string
end

def capture_stderr(&block)
  original_stderr = $stderr
  $stderr = fake = StringIO.new

  begin
    yield
  ensure
    $stderr = original_stderr
  end

  fake.string
end

def fixture_path(filename)
  File.join('spec', 'fixtures', filename)
end

def stub_redirects(urls, status = 301)
  urls.each_cons(2) do |url_from, url_to|
    stub_request(:head, url_from).to_return(
      status: status, headers: { location: url_to }
    )
  end
end

require 'mail'

Mail.defaults do
  delivery_method :test
end

require 'sequel'
require 'feed2email'

Feed2Email.setup_database(connection: Sequel.sqlite)
