RSpec.describe Granite::Routing::Mapper do
  subject { Object.new.extend described_class }

  describe '#granite' do
    let(:path) { 'ba/student/pause#modal' }
    let(:route) { double }
    let(:options) { {path: 1, as: 2, projector_prefix: 3, foo: 4} }

    before do
      stub_const 'Granite::Routing::Declarer', spy
      stub_const 'Granite::Routing::Route', double
      allow(Granite::Routing::Route).to receive(:new).with(path, **options.except(:foo)).and_return(route)
    end

    specify do
      subject.granite(path, **options)
      expect(Granite::Routing::Declarer).to have_received(:declare)
        .with(subject, route, **options.except(:path, :as, :projector_prefix))
    end
  end
end
