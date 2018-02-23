RSpec.describe Granite::Routing::Caching do
  subject { dummy_class.new }

  super_module = Module.new do
    def clear_cache!
    end
  end

  let(:dummy_class) do
    Class.new do
      include super_module
      include Granite::Routing::Caching

      def initialize
        @granite_cache = 'some_value'
      end

      def cache
        instance_variable_get(:@granite_cache)
      end
    end
  end

  describe '#granite_cache' do
    context 'when granite_cache is present' do
      it 'returns current value' do
        expect(subject.granite_cache).to eq 'some_value'
      end
    end

    context 'when granite_cache is not present' do
      before { subject.clear_cache! }

      it 'returns instance of Cache' do
        expect(subject.granite_cache).to be_kind_of Granite::Routing::Cache
      end
    end
  end

  describe '#clear_cache!' do
    it 'calls super' do
      allow_any_instance_of(super_module).to receive(:super)
    end

    it 'sets granite_cache to nil' do
      expect { subject.clear_cache! }.to change { subject.cache }.to(nil)
    end
  end
end
