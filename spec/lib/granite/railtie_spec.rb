RSpec.describe Granite::Railtie do
  subject { described_class.new }

  describe '#initializer' do
    let(:app) { double.as_null_object }

    specify do
      allow(app.config.paths).to receive(:add)
      described_class.initializers.each { |initializer| initializer.run(app) }
      expect(app.config.paths)
        .to have_received(:add)
        .with('apq', eager_load: true, glob: '{actions,projectors}{,/concerns}')
    end
  end
end
