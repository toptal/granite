RSpec.describe Granite::Action::Performer do
  let(:first_performer) { instance_double(User, id: 5) }
  let(:second_performer) { instance_double(User, id: 10) }

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
    specify { expect(Action.new.ctx).to be_nil }
    specify { expect(Action.with(performer: :value).new.ctx).to have_attributes(performer: :value) }
    specify { expect(Action.as(first_performer).new.ctx).to have_attributes(performer: first_performer) }

    specify 'proxy works for deeper initialization' do
      expect(Action.with(performer: :value).batch(2).map(&:ctx))
        .to contain_exactly(have_attributes(performer: :value), have_attributes(performer: :value))
    end
  end

  describe '#performer' do
    specify { expect(Action.new.performer).to be_nil }
    specify { expect(Action.as(first_performer).new.performer).to eq(first_performer) }

    specify 'proxy works for deeper initialization' do
      expect(Action.as(first_performer).batch(2).map(&:performer)).to eq([first_performer, first_performer])
    end
  end

  describe '#performer_id' do
    specify { expect(Action.new.performer_id).to be_nil }
    specify { expect(Action.as(first_performer).new.performer_id).to eq(first_performer.id) }
  end
end
