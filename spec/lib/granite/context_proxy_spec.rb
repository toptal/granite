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
  let(:performer) { performers.first }
  let(:performers) { 10.times.map { |i| instance_double(User, "Performer #{i}") } }
  let(:context) { {performer: performer} }
  let(:proxy) { instance_double(Granite::ContextProxy::Proxy) }

  describe '.with' do
    before do
      allow(Granite::ContextProxy::Proxy).to receive(:new).with(klass, have_attributes(**context)) { proxy }
    end

    specify do
      expect(klass.with(context)).to eq proxy
    end
  end

  describe '.as' do
    before do
      allow(Granite::ContextProxy::Proxy).to receive(:new).with(klass, have_attributes(**context)) { proxy }
    end

    specify do
      expect(klass.as(performer)).to eq proxy
    end
  end

  describe '.with_context' do
    specify do
      expect { |b| klass.with_context(context, &b) }.to yield_with_no_args
    end

    it 'sets proxy_content inside block' do
      klass.with_context(context) do
        expect(klass.proxy_context).to eq context
      end
      expect(klass.proxy_context).to be_nil
    end

    it 'correctly works with nested contexts' do
      klass.with_context(context) do
        expect(klass.proxy_context).to eq context
        klass.with_context(performer: performers.second) do
          expect(klass.proxy_context).to eq(performer: performers.second)
        end
        expect(klass.proxy_context).to eq context
      end
    end
  end

  describe '.proxy_context' do
    before do
      Thread.current[:granite_proxy_context] = context
    end

    after do
      Thread.current[:granite_proxy_context] = nil
    end

    specify do
      expect(klass.proxy_context).to eq context
    end
  end
end
