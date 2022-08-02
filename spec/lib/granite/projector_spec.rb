RSpec.describe Granite::Projector do
  before do
    stub_class(:action, Granite::Action)
    stub_class(:projector, Granite::Projector) do
      self.action_class = Action
    end
    stub_class(:descendant, Projector)
  end

  describe '.using' do
    let(:context) { {performer: instance_double(Student)} }
    specify { expect(Projector.using(context).new.action.ctx).to eq(context) }
  end

  describe '.controller_class' do
    specify { expect(described_class.controller_class).to eq(Granite::Controller) }
    specify { expect(Projector.controller_class).to be < Granite::Controller }
    specify { expect(Descendant.controller_class).to be < Projector.controller_class }
    specify { expect(Descendant.controller_class).not_to eq(Projector.controller_class) }

    specify { expect(described_class.controller_class.projector_class).to be_nil }
    specify { expect(Projector.controller_class.projector_class).to eq(Projector) }
    specify { expect(Descendant.controller_class.projector_class).to eq(Descendant) }
  end

  describe '.projector_path' do
    specify { expect(stub_class(:some_projector, described_class).projector_path).to eq('some') }
    specify { expect(stub_class('directory/some_projector', described_class).projector_path).to eq('directory/some') }
  end

  describe '.projector_name' do
    specify { expect(stub_class(:some_projector, described_class).projector_name).to eq('some') }
    specify { expect(stub_class('directory/some_projector', described_class).projector_name).to eq('some') }
  end

  describe '#initialize' do
    describe 'old approach' do
      specify { expect(Projector.new(Action.new).action).to be_an Action }
    end

    describe 'new approach' do
      let(:params) { [double, double] }
      let(:action) { double }

      it 'builds an action from params' do
        allow(Action).to receive(:new).with(*params).and_return(action)
        expect(Projector.new(*params).action).to eq action
      end
    end
  end
end
