require 'pry'
require 'feed2email'

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'
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
