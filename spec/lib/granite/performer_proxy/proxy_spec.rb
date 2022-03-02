# spec: unit

require 'granite/performer_proxy/proxy'

RSpec.describe Granite::PerformerProxy::Proxy do
  subject { described_class.new(klass, performer) }

  let(:klass) { class_double('DummyClass', to_s: 'DummyClass') }
  let(:performer) { instance_double('Performer', to_s: '#Performer') }

  its(:inspect) { is_expected.to eq('<DummyClassPerformerProxy #Performer>') }

  describe '#method_missing' do
    specify 'when klass does not respond to a method' do
      expect { subject.func }.to raise_error NoMethodError
    end

    context 'when klass responds to a method' do
      let(:klass) { class_double('DummyClass', func: 'value') }

      specify do
        expect(klass).to receive(:with_proxy_performer).with(performer).and_yield
        subject.func('value')
      end
    end
  end

  describe '#respond_to_missing?' do
    specify 'when class does not respond to a method' do
      expect(subject.__send__(:respond_to_missing?, :func)).to be(false)
    end

    context 'when klass responds to a method' do
      let(:klass) { class_double('DummyClass', func: 'value') }

      specify do
        expect(subject.__send__(:respond_to_missing?, :func)).to be(true)
      end
    end
  end
end
