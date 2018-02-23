RSpec.describe Granite::Action::Preconditions do
  context 'with block' do
    before do
      stub_class(:action, Granite::Action) do
        attribute :title, String

        precondition do
          decline_with(:wrong_title) if title !~ /Ruby/
        end
        # Just to check that validations are not run if preconditions are not satisfied
        validates :title, inclusion: {in: ['Ruby']}
      end
    end

    describe '#satisfy_preconditions?' do
      specify { expect(Action.new(title: 'Delphi')).not_to satisfy_preconditions }
      specify { expect(Action.new(title: 'Ruby')).to satisfy_preconditions }
    end

    describe '#failed_preconditions' do
      subject { action.failed_preconditions }
      let(:action) { Action.new(title: 'Delphi') }
      it { is_expected.to eq [] }
      specify do
        action.satisfy_preconditions?
        expect(subject).to eq [:wrong_title]
      end
    end

    describe '#valid?' do
      specify { expect(Action.new(title: 'Delphi')).not_to be_valid }
      specify { expect(Action.new(title: 'Ruby')).to be_valid }
    end

    describe '#errors' do
      context do
        let(:action) { Action.new(title: 'Delphi') }
        specify do
          expect { action.valid? }.to change { action.errors.messages }
            .to(base: match_array(['Wrong title']))
        end
      end

      context do
        let(:action) { Action.new(title: 'Rubyist') }
        specify do
          expect { action.valid? }.to change { action.errors.messages }
            .to(title: ['is not included in the list'])
        end
      end

      context do
        let(:action) { Action.new(title: 'Ruby') }
        specify do
          expect { action.valid? }.not_to change { action.errors.messages }
        end
      end
    end
  end

  context 'with options' do
    before do
      stub_class(:action_title, Granite::Action) do
        attribute :title, String

        precondition if: -> { title.length > 3 } do
          decline_with(:wrong_title) if title !~ /Ruby/
        end
      end

      stub_class(:action, Granite::Action) do
        attribute :title, String

        precondition embedded: :action_title

        def action_title
          ActionTitle.new(title: title) if title
        end
      end
    end

    describe '#satisfy_preconditions?' do
      specify { expect(Action.new(title: nil)).to satisfy_preconditions }
      specify { expect(Action.new(title: 'Ada')).to satisfy_preconditions }
      specify { expect(Action.new(title: 'Delphi')).not_to satisfy_preconditions }
      specify { expect(Action.new(title: 'Ruby')).to satisfy_preconditions }
    end
  end

  context 'with args defaulting to empty list' do
    before do
      stub_class(:action, Granite::Action) do
        attribute :title, String

        precondition :embedded
      end
    end

    describe '#satisfy_preconditions?' do
      specify { expect(Action.new(title: nil)).to satisfy_preconditions }
    end
  end
end
