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
require 'active_record'
require 'rack/test'
require 'action_controller/metal/strong_parameters'
require 'granite'
require 'granite/rspec'
require 'database_cleaner'

SimpleCov.start do
  minimum_coverage 99.66
end

Granite.tap do |config|
  config.base_controller = 'ApplicationController'
end

Dir['./spec/support/**/*.rb'].sort.each { |f| require f }

RSpec.configure do |config|
  config.fail_if_no_examples = true

  config.order = :random

  config.disable_monkey_patching!

  # Use the documentation formatter for detailed output
  config.default_formatter = config.files_to_run.one? ? 'doc' : 'Fuubar'

  if ENV.key?('CI_NODE_INDEX')
    config.before(:example, :focus) { raise 'Should not commit focused specs' }
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

  config.before(:suite) do
    DatabaseCleaner.clean_with :truncation
    DatabaseCleaner.strategy = :transaction
  end

  config.before do
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end

  config.include ModelHelpers
  config.include MuffleHelpers
end
