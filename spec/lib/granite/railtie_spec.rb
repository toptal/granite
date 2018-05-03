RSpec.describe Granite::Railtie do
  subject { described_class.new }

  describe '#initializer' do
    specify do
      app = double.as_null_object
      expect(app.config.paths).to receive(:add).with('apq', eager_load: true, glob: '{actions,projectors}{,/concerns}')
      Granite::Railtie.initializers.each { |initializer| initializer.run(app) }
    end
  end
end
