RSpec.describe Granite::Action::Performer do
  let(:performer1) { instance_double(User, id: 5) }
  let(:performer2) { instance_double(User, id: 10) }

  before do
    stub_class(:projector, Granite::Projector)
    stub_class(:action, Granite::Action) do
      projector :projector

      def self.batch(count)
        Array.new(count).map { new }
      end
    end
  end

  describe '#ctx' do
    specify { expect(Action.new.ctx).to eq({}) }
    specify { expect(Action.using(key: :value).new.ctx).to eq(key: :value) }
    specify { expect(Action.as(performer1).new.ctx).to eq(performer: performer1) }

    specify 'proxy works for deeper initialization' do
      expect(Action.using(key: :value).batch(2).map(&:ctx)).to eq([{key: :value}, {key: :value}])
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
