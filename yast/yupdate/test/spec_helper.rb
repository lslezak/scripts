if ENV["COVERAGE"]
  require "simplecov"

  # use coveralls for on-line code coverage reporting at Travis CI
  if ENV["TRAVIS"]
    require "coveralls"

    SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
      SimpleCov::Formatter::HTMLFormatter,
      Coveralls::SimpleCov::Formatter
    ]
  end

  SimpleCov.start do
    add_filter "/test/"
  end
end

require_relative "../yupdate"

# configure RSpec
RSpec.configure do |config|
  config.mock_with :rspec do |c|
    # https://relishapp.com/rspec/rspec-mocks/v/3-0/docs/verifying-doubles/partial-doubles
    c.verify_partial_doubles = true
  end
end

# a helper method to capture both $stdout and $stderr streams
def capture_stdio(&block)
  stdout_orig = $stdout
  stderr_orig = $stderr

  $stdout = StringIO.new
  $stderr = StringIO.new
  begin
    yield
    [$stdout.string, $stderr.string]
  ensure
    $stdout = stdout_orig
    $stderr = stderr_orig
  end
end
