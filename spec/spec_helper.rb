require 'simplecov'
SimpleCov.start

require 'mail'
Mail.defaults { delivery_method :test }

require 'sequel'
require 'feed2email'
Feed2Email.setup_database(connection: Sequel.sqlite)

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

  config.before(:each) do
    Feed2Email.home_path = Dir.mktmpdir

    Mail::TestMailer.deliveries.clear
  end

  config.around(:each) do |example|
    Sequel::Model.db.transaction(rollback: :always, auto_savepoint: true) do
      example.run
    end
  end
end

def discard_output
  stdout, stderr = $stdout, $stderr # backup
  $stdout = $stderr = StringIO.new
  yield
  $stdout, $stdeer = stdout, stderr # restore
end

def discard_thor_error
  begin
    yield
  rescue Thor::Error
  end
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
