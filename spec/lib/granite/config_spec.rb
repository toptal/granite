RSpec.describe Granite::Config do
  let(:config) { described_class.__send__(:new) }

  describe '#base_controller_class' do
    subject { config.base_controller_class }

    it { is_expected.to eq ActionController::Base }

    context 'when base_controller is set' do
      let!(:controller_class) { stub_class('GraniteConfigTestController', ActionController::Base) }

      before { config.base_controller = 'GraniteConfigTestController' }

      it { is_expected.to eq controller_class }

      context 'with invalid value' do
        before { config.base_controller = 'NonExistingController' }

        specify { expect { subject }.to raise_error NameError, /uninitialized constant NonExistingController/ }
      end

      context 'with live reload' do
        let(:controller_class_reloaded) { stub_class('GraniteConfigTestController', ActionController::Base) }
        specify do
          expect(config.base_controller_class).to eq controller_class
          controller_class_reloaded
          expect(config.base_controller_class).to eq controller_class_reloaded
        end
      end
    end
  end
end
