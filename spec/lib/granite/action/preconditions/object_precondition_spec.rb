RSpec.describe Granite::Action::Preconditions::ObjectPrecondition do
  before do
    stub_class(:title_precondition, Granite::Action::Precondition) do
      def call(expected_title:, **)
        decline_with(:wrong_title) if title != expected_title
      end
    end
  end

  context 'with simple declaration' do
    before do
      stub_class(:action, Granite::Action) do
        attribute :title, String

        precondition TitlePrecondition, expected_title: 'Ruby'
      end
    end

    describe '#satisfy_preconditions?' do
      specify { expect(Action.new(title: 'Delphi')).not_to satisfy_preconditions }
      specify { expect(Action.new(title: 'Ruby')).to satisfy_preconditions }
    end
  end

  context 'with :if option' do
    before do
      stub_class(:action, Granite::Action) do
        attribute :title, String

        precondition TitlePrecondition, expected_title: 'Ruby', if: -> { title.length > 3 }
      end
    end

    describe '#satisfy_preconditions?' do
      specify { expect(Action.new(title: 'Ada')).to satisfy_preconditions }
      specify { expect(Action.new(title: 'Delphi')).not_to satisfy_preconditions }
      specify { expect(Action.new(title: 'Ruby')).to satisfy_preconditions }
    end
  end

  context 'with :unless option' do
    before do
      stub_class(:action, Granite::Action) do
        attribute :title, String

        precondition TitlePrecondition, expected_title: 'Ruby', unless: -> { title.length > 4 }
      end
    end

    describe '#satisfy_preconditions?' do
      specify { expect(Action.new(title: 'Ada')).not_to satisfy_preconditions }
      specify { expect(Action.new(title: 'Delphi')).to satisfy_preconditions }
      specify { expect(Action.new(title: 'Ruby')).to satisfy_preconditions }
    end
  end
end
