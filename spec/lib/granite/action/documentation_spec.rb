RSpec.describe Granite::Action::Documentation do
  before do
    stub_class(:action, Granite::Action) do
      domain 'library'
      desc 'Allows to borrow a book'
    end
  end

  specify do
    expect(Action._domain).to eq('library')
    expect(Action._description).to eq('Allows to borrow a book')
  end
end
