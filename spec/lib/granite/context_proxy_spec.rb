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
  let(:performers) { 2.times.map { instance_double(User) } }
  let(:context) { {performer: performer} }
  let(:proxy) { instance_double(Granite::ContextProxy::Proxy) }

  describe '.using' do
    before do
      allow(Granite::ContextProxy::Proxy).to receive(:new).with(klass, have_attributes(**context)) { proxy }
    end

    specify do
      expect(klass.using(context)).to eq proxy
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

    it 'keeps context in thread safe way' do
      thread_performers = []
      threads = 2.times.map do |i|
        Thread.new do
          klass.with_context(performer: performers[i]) do
            Thread.stop
            thread_performers << klass.proxy_context[:performer]
          end
        end
      end
      sleep 0.01 until threads.all?(&:stop?)
      threads.each { |thread| thread.run.join }
      expect(thread_performers).to eq(performers)
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
