require 'rails/generators'
require 'rails/generators/testing/behaviour'
require_relative '../../../lib/generators/granite_generator'

RSpec.describe GraniteGenerator do
  include RSpec::Rails::RailsExampleGroup
  include Rails::Generators::Testing::Behaviour
  include FileUtils

  tests described_class
  destination File.join(Dir.tmpdir, 'granite')

  before { prepare_destination }

  def destination_path(generated_name)
    Pathname(destination_root).join(generated_name)
  end

  def expect_same_content(generated_name, example_name)
    example_path = Pathname("../../../fixtures/#{example_name}_example.rb").expand_path(__FILE__)
    generated_path = destination_path(generated_name)

    expect(generated_path).to be_file
    expect(generated_path.read).to eq(example_path.read)
  end

  def entries
    destination_path('apq/actions/user/').entries.map(&:to_s) - %w[. ..]
  end

  specify do
    run_generator %w[user/create]
    expect(entries).to match_array(%w[create.rb business_action.rb])
    expect_same_content('apq/actions/user/business_action.rb', 'base_action')
    expect_same_content('apq/actions/user/create.rb', 'action')
    expect_same_content('spec/apq/actions/user/create_spec.rb', 'action_spec')
  end

  specify do
    run_generator %w[user/create -C]
    expect(entries).to match_array(%w[create.rb])
    expect_same_content('apq/actions/user/create.rb', 'collection_action')
    expect_same_content('spec/apq/actions/user/create_spec.rb', 'collection_action_spec')
  end

  specify do
    run_generator %w[user/create simple]
    expect(entries).to match_array(%w[create create.rb business_action.rb])
    expect(destination_path('apq/actions/user/create/simple/')).to be_directory
    expect_same_content('apq/actions/user/create.rb', 'simple_action')
  end
end
