# spec: unit

require 'granite/performer_proxy/proxy'

RSpec.describe Granite::PerformerProxy::Proxy do
  subject { described_class.new(klass, performer) }

  let(:klass) { stub_class('DummyClass') }
  let(:performer) { instance_double(User, to_s: '#Performer') }

  its(:inspect) { is_expected.to eq('<DummyClassPerformerProxy #Performer>') }

  describe '#method_missing' do
    specify 'when klass does not respond to a method' do
      expect { subject.func }.to raise_error NoMethodError
    end

    context 'when klass responds to a method' do
      before do
        klass.define_singleton_method(:func) { |_| 'value' }
      end

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
      before do
        klass.define_singleton_method(:func) { 'value' }
      end

      specify do
        expect(subject.__send__(:respond_to_missing?, :func)).to be(true)
      end
    end
  end
end
