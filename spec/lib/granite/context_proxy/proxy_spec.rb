# spec: unit

require 'granite/context_proxy/proxy'

RSpec.describe Granite::ContextProxy::Proxy do
  subject(:proxy) { described_class.new(klass, context) }

  let(:klass) { stub_class('DummyClass') }
  let(:context) { { performer: '#Performer' } }

  its(:inspect) { is_expected.to eq('<DummyClassContextProxy {:performer=>"#Performer"}>') }

  describe '#method_missing' do
    specify 'when klass does not respond to a method' do
      expect { proxy.func }.to raise_error NoMethodError
    end

    context 'when klass responds to a method' do
      before do
        klass.define_singleton_method(:func) { |_| 'value' }
      end

      specify do
        allow(klass).to receive(:with_context).with(context).and_yield
        proxy.func('value')
        expect(klass).to have_received(:with_context).with(context)
      end
    end
  end

  describe '#respond_to_missing?' do
    specify 'when class does not respond to a method' do
      expect(proxy.__send__(:respond_to_missing?, :func)).to be(false)
    end

    context 'when klass responds to a method' do
      before do
        klass.define_singleton_method(:func) { 'value' }
      end

      specify do
        expect(proxy.__send__(:respond_to_missing?, :func)).to be(true)
      end
    end
  end
end
