RSpec.describe Granite::Routing::Route do
  subject { described_class.new('ba/sample#modal') }

  its(:action_path) { is_expected.to eq 'ba/sample' }
  its(:projector_name) { is_expected.to eq 'modal' }

  describe '#path' do
    context 'with explicit path passed' do
      subject { described_class.new('ba/sample#modal', path: 'my_path') }

      its(:path) { is_expected.to eq 'my_path(/:projector_action)' }
    end

    context 'without explicit path passed' do
      its(:path) { is_expected.to eq 'sample(/:projector_action)' }
    end

    context 'with projector_prefix: true' do
      subject { described_class.new('ba/sample#modal', projector_prefix: true) }

      its(:path) { is_expected.to eq 'modal_sample(/:projector_action)' }
    end
  end

  describe '#as' do
    context 'with explicit as passed' do
      subject { described_class.new('ba/sample#modal', as: 'me') }

      its(:as) { is_expected.to eq 'me' }
    end

    context 'without explicit as passed' do
      its(:as) { is_expected.to eq 'sample' }
    end

    context 'with projector_prefix: true' do
      subject { described_class.new('ba/sample#modal', projector_prefix: true) }

      its(:as) { is_expected.to eq 'modal_sample' }
    end
  end
end
