require 'bundler/setup'

# Add project root to load paths with or without rails
# PROJECT_ROOT = File.expand_path('..', __dir__)
# warn PROJECT_ROOT: PROJECT_ROOT
# $LOAD_PATH << PROJECT_ROOT

require_relative 'support/rails'

require 'rspec'
require 'rspec/its'
require 'rspec/rails'
require 'rspec/matchers/fail_matchers'
require 'simplecov'
SimpleCov.start do
  minimum_coverage 99.73
end

require 'granite'
Granite.tap do |config|
  config.base_controller = 'ApplicationController'
end

require 'granite/rspec'

RSpec.configure do |config|
  config.fail_if_no_examples = true

  config.order = :random

  config.disable_monkey_patching!

  # Use the documentation formatter for detailed output
  config.default_formatter = config.files_to_run.one? ? 'doc' : 'Fuubar'

  if ENV.key?('CI_NODE_INDEX')
    config.before(:example, :focus) { fail 'Should not commit focused specs' }
  else
    config.filter_run focus: true
    config.run_all_when_everything_filtered = true
  end

  config.around(:each, time_zone: ->(value) { value.present? }) do |example|
    Time.use_zone(example.metadata[:time_zone]) { example.run }
  end

  config.include RSpec::Matchers::FailMatchers, file_path: %r{spec/lib/granite/rspec/}

  config.expect_with :rspec do |c|
    c.max_formatted_output_length = nil
  end
end

Dir['./spec/support/**/*.rb'].sort.each { |f| require f }
