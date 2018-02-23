# spec: unit

require 'granite/performer_proxy'

RSpec.describe Granite::PerformerProxy do
  subject { klass.new }
  let(:klass) { class_double('DummyClass', hash: 'hash').tap { |k| k.include Granite::PerformerProxy } }
  let(:performer) { instance_double('Performer') }
  let(:proxy) { instance_double('Granite::PerformerProxy::Proxy') }

  describe '.as' do
    before do
      allow(Granite::PerformerProxy::Proxy).to receive(:new).with(klass, performer) { proxy }
    end

    specify do
      expect(klass.as(performer)).to eq proxy
    end
  end

  describe '.with_proxy_performer' do
    specify do
      expect { |b| klass.with_proxy_performer(performer, &b) }.to yield_with_no_args
    end

    specify do
      klass.with_proxy_performer(performer) do
        expect(Thread.current[:granite_proxy_performer_hash]).to eq performer
      end
    end
  end

  describe '.proxy_performer' do
    before do
      Thread.current[:granite_proxy_performer_hash] = performer
    end

    specify do
      expect(klass.proxy_performer).to eq performer
    end
  end
end
