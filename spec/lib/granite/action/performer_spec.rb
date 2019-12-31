RSpec.describe Granite::Action::Performer do
  let(:performer1) { instance_double('Performer', id: 5) }
  let(:performer2) { instance_double('Performer', id: 10) }

  before do
    stub_class(:projector, Granite::Projector)
    stub_class(:action, Granite::Action) do
      projector :projector

      def self.batch(count)
        Array.new(count).map { new }
      end
    end
  end

  describe '#performer' do
    specify { expect(Action.new.performer).to be_nil }
    specify { expect(Action.as(performer1).new.performer).to eq(performer1) }

    specify 'proxy works for deeper initialization' do
      expect(Action.as(performer1).batch(2).map(&:performer)).to eq([performer1, performer1])
    end
  end

  describe '#performer_id' do
    specify { expect(Action.new.performer_id).to be_nil }
    specify { expect(Action.as(performer1).new.performer_id).to eq(performer1.id) }
  end
end
