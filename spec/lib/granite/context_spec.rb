RSpec.describe Granite::Context do
  subject(:config) { described_class.__send__(:new) }

  describe '#with_view_context' do
    let(:view_context) { Object.new }

    specify { expect(config.with_view_context(view_context) { 'result' }).to eq('result') }
    specify do
      expect(config.view_context).to be_nil
      config.with_view_context(view_context) do
        expect(config.view_context).to eq(view_context)
        begin
          config.with_view_context(nil) do
            expect(config.view_context).to be_nil
            fail
          end
        rescue # rubocop:disable Lint/HandleExceptions
        end
        expect(config.view_context).to eq(view_context)
      end
      expect(config.view_context).to be_nil
    end
  end
end
