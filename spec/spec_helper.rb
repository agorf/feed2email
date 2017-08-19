require 'simplecov'
SimpleCov.start

require 'mail'
Mail.defaults { delivery_method :test }

require 'feed2email'
require 'sequel'
Feed2Email.setup_database(connection: Sequel.sqlite)
Feed2Email.home_path = Dir.mktmpdir

require 'fileutils'
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
    if Feed2Email.root_path.start_with?('/tmp/')
      FileUtils.rm_rf(Feed2Email.root_path)
      FileUtils.mkdir_p(Feed2Email.root_path)
    end

    Mail::TestMailer.deliveries.clear
  end

  config.around(:each) do |example|
    Sequel::Model.db.transaction(rollback: :always, auto_savepoint: true) do
      example.run
    end
  end
end

$orig_stdout = $stdout # backup

def discard_stdout
  $stdout = open(File::NULL, 'w')
  yield
  $stdout.close
  $stdout = $orig_stdout
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
