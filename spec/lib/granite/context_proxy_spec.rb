# spec: unit

require 'granite/context_proxy'

RSpec.describe Granite::ContextProxy do
  subject { klass.new }
  let(:klass) do
    Class.new do
      include Granite::ContextProxy

      def self.hash
        'hash'
      end
    end
  end
  let(:performer) { instance_double(User) }
  let(:context) { {performer: performer} }
  let(:proxy) { instance_double(Granite::ContextProxy::Proxy) }

  describe '.using' do
    before do
      allow(Granite::ContextProxy::Proxy).to receive(:new).with(klass, context) { proxy }
    end

    specify do
      expect(klass.using(context)).to eq proxy
    end
  end

  describe '.as' do
    before do
      allow(Granite::ContextProxy::Proxy).to receive(:new).with(klass, {performer: performer}) { proxy }
    end

    specify do
      expect(klass.as(performer)).to eq proxy
    end
  end

  describe '.with_context' do
    specify do
      expect { |b| klass.with_context(context, &b) }.to yield_with_no_args
    end

    specify do
      klass.with_context(context) do
        expect(Thread.current[:granite_proxy_performer_hash]).to eq context
      end
    end
  end

  describe '.proxy_context' do
    before do
      Thread.current[:granite_proxy_performer_hash] = context
    end

    after do
      Thread.current[:granite_proxy_performer_hash] = nil
    end

    specify do
      expect(klass.proxy_context).to eq context
    end
  end
end
