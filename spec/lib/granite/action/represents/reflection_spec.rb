# spec: unit

require 'granite/action'
require 'granite/action/represents/reflection'

RSpec.describe Granite::Action::Represents::Reflection do
  describe '.attribute_class' do
    subject { described_class }

    its(:attribute_class) { is_expected.to eq Granite::Action::Represents::Attribute }
  end
end
