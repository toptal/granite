RSpec.describe Granite::Action::Types::Collection do
  subject { described_class.new(subtype_definition) }
  let(:subtype_definition) { Granite::Form::Types::Object.new(Dummy, nil, nil) }
  let(:dummy_object) { Dummy.new }

  before { stub_class :dummy }

  describe '#ensure_type' do
    specify { expect(subject.ensure_type([dummy_object, Object.new])).to eq([dummy_object, nil]) }
    specify { expect(subject.ensure_type({one: dummy_object, two: Object.new})).to eq({one: dummy_object, two: nil}) }
  end
end
