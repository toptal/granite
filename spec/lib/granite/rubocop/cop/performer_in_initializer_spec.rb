require 'rubocop/rspec/support'
require 'granite/rubocop/cop/performer_in_initializer'

RSpec.describe RuboCop::Cop::Granite::PerformerInInitializer do
  subject(:cop) { described_class.new }

  let(:message) { described_class::MSG }

  before do
    inspect_source(source)
  end

  shared_examples 'code without offense' do |code|
    let(:source) { code }

    it 'does not register an offense' do
      expect(cop.offenses).to be_empty
    end
  end

  shared_examples 'code with offense' do |code, corrected = nil|
    let(:source) { code }

    it 'registers an offense' do
      expect(cop.offenses.size).to eq(1)
      expect(cop.messages).to eq([message])
    end

    if corrected
      it 'auto-corrects' do
        expect(autocorrect_source(code)).to eq(corrected)
      end
    else
      it 'does not auto-correct' do
        expect(autocorrect_source(code)).to eq(code)
      end
    end
  end

  context 'when is not a real Business Action' do
    it_behaves_like 'code without offense',
                    'NotBusinessAction.new(performer: current_role)'

    it_behaves_like 'code without offense',
                    'NotBA::Subject::Action.new(performer: current_role)'

    it_behaves_like 'code without offense',
                    '5.inspect'
  end

  context 'when already using the new syntax' do
    code = 'BA::Subject::Action.as(attributes.delete(:performer)).new(attributes)'
    it_behaves_like 'code without offense', code
  end

  context 'when checking specs using `described_class`' do
    context 'with subject and performer' do
      code = <<-CODE
      describe BA::Subject::Action do
        let(:user)   { create(:user) }
        let(:action) { described_class.new(performer: user, other: 'param') }
      end
      CODE
      corrected = <<-CORRECTED
      describe BA::Subject::Action do
        let(:user)   { create(:user) }
        let(:action) { described_class.as(user).new(other: 'param') }
      end
      CORRECTED
      it_behaves_like 'code with offense', code, corrected
    end

    context 'when describe block exists' do
      code = <<-CODE
        RSpec.describe BA::Subject::CustomAction do
          describe do
          end
        end
      CODE

      it_behaves_like 'code without offense', code
    end

    context 'when params merged with another hash' do
      context 'when performer is on the left side of the merge' do
        code = 'BA::Subject::Action.new(subject, {performer: current_role}.merge(prohibited_location_attributes)).perform!'
        corrected = 'BA::Subject::Action.as(current_role).new(subject, {}.merge(prohibited_location_attributes)).perform!'

        it_behaves_like 'code with offense', code, corrected
      end

      context 'when performer is on the right side of the merge' do
        code = 'let!(:job) { BA::Subject::Action.new(subject_attribute.merge(performer: performer)).perform! }'
        corrected = 'let!(:job) { BA::Subject::Action.as(performer).new(subject_attribute.merge({})).perform! }'

        it_behaves_like 'code with offense', code, corrected
      end
    end

    context 'when using `Rspec.describe` notation' do
      code = <<-CODE
        RSpec.describe BA::Subject::Action do
          subject(:action) { described_class.new(performer: current_role) }
        end
      CODE

      corrected = <<-CODE
        RSpec.describe BA::Subject::Action do
          subject(:action) { described_class.as(current_role).new() }
        end
      CODE

      it_behaves_like 'code with offense', code, corrected
    end
  end

  context 'when performer is not passed to the initializer' do
    it_behaves_like 'code without offense',
                    'BA::Subject::Action.as_system.new(other: parameter)'
  end

  context 'when performer is passed to the initializer' do
    context 'when performer is given as {expression}' do
      context 'when performer is a method chain' do
        it_behaves_like 'code with offense',
                        'BA::Subject::Action.new(other: parameter, performer: subject.author)',
                        'BA::Subject::Action.as(subject.author).new(other: parameter)'
      end

      context 'when performer is a single method call or a variable' do
        it_behaves_like 'code with offense',
                        'BA::Subject::Action.new(document, performer: performer).perform!',
                        'BA::Subject::Action.as(performer).new(document).perform!'
      end
    end

    context 'when subject is the first parameter and performer is the second parameter' do
      it_behaves_like 'code with offense',
                      'BA::Subject::Action.new(subject, performer: object.message)',
                      'BA::Subject::Action.as(object.message).new(subject)'

      it_behaves_like 'code with offense',
                      'BA::Subject::Action.new(subject, performer: ::Object.new).perform!',
                      'BA::Subject::Action.as(::Object.new).new(subject).perform!'
    end

    context 'when there are other method calls before new' do
      it_behaves_like 'code with offense',
                      'BA::Subject::Action.modal.new(performer: performer)'

      it_behaves_like 'code with offense',
                      'BA::Subject::Action.for(step_type).new(performer: performer)'

      it_behaves_like 'code with offense',
                      'BA::Subject::Action.modal.new(subject.company, performer: action.performer)'
    end

    context 'when multi-line initializer' do
      context 'with other performer' do
        code = <<-CODE
          BA::Subject::Action.new(subject,
              performer: performer,
              other_param: param)
        CODE
        corrected = <<-CORRECTED
          BA::Subject::Action.as(performer).new(subject,
              other_param: param)
        CORRECTED

        it_behaves_like 'code with offense', code, corrected
      end

      context 'with other performer' do
        code = <<-CODE
          BA::Subject::Action.new(subject,
              performer: performer,
              other_param: param)
        CODE
        corrected = <<-CORRECTED
          BA::Subject::Action.as(performer).new(subject,
              other_param: param)
        CORRECTED

        it_behaves_like 'code with offense', code, corrected
      end

      context 'with multiple params' do
        code = <<-CODE
          BA::Subject::Action.new(subject,
              performer: performer,
              first: param,
              second: param
          )
        CODE
        corrected = <<-CORRECTED
          BA::Subject::Action.as(performer).new(subject,
              first: param,
              second: param
          )
        CORRECTED

        it_behaves_like 'code with offense', code, corrected
      end
    end
  end
end
