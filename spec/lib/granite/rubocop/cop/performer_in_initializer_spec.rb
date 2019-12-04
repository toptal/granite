require 'rubocop/rspec/support'
require 'granite/rubocop/cop/performer_in_initializer'

RSpec.configure do |config|
  config.include RuboCop::RSpec::ExpectOffense
end

RSpec.describe RuboCop::Cop::Granite::PerformerInInitializer do
  subject(:cop) { described_class.new }

  context 'when is not a real Business Action' do
    it { expect_no_offenses 'NotBusinessAction.new(performer: current_role)' }

    it { expect_no_offenses 'NotBA::Subject::Action.new(performer: current_role)' }

    it { expect_no_offenses '5.inspect' }
  end

  context 'when already using the new syntax' do
    it { expect_no_offenses 'BA::Subject::Action.as(attributes.delete(:performer)).new(attributes)' }
  end

  context 'when checking specs using `described_class`' do
    context 'with subject and performer' do
      it do
        expect_offense <<-RUBY
          describe BA::Subject::Action do
            let(:user)   { create(:user) }
            let(:action) { described_class.new(performer: user, other: 'param') }
                           ^^^^^^^^^^^^^^^ Use `.as(performer)` instead of passing performer to the initializer
          end
        RUBY

        expect_correction <<-RUBY
          describe BA::Subject::Action do
            let(:user)   { create(:user) }
            let(:action) { described_class.as(user).new(other: 'param') }
          end
        RUBY
      end
    end

    context 'when describe block exists' do
      it do
        expect_no_offenses <<-RUBY
          RSpec.describe BA::Subject::CustomAction do
            describe do
            end
          end
        RUBY
      end
    end

    context 'when params merged with another hash' do
      context 'when performer is on the left side of the merge' do
        it do
          expect_offense <<-RUBY
            BA::Subject::Action.new(subject, {performer: current_role}.merge(prohibited_location_attributes)).perform!
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `.as(performer)` instead of passing performer to the initializer
          RUBY

          expect_correction <<-RUBY
            BA::Subject::Action.as(current_role).new(subject, {}.merge(prohibited_location_attributes)).perform!
          RUBY
        end
      end

      context 'when performer is on the right side of the merge' do
        it do
          expect_offense <<-RUBY
            let!(:job) { BA::Subject::Action.new(subject_attribute.merge(performer: performer)).perform! }
                         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `.as(performer)` instead of passing performer to the initializer
          RUBY

          expect_correction <<-RUBY
            let!(:job) { BA::Subject::Action.as(performer).new(subject_attribute.merge({})).perform! }
          RUBY
        end
      end
    end

    context 'when using `Rspec.describe` notation' do
      it do
        expect_offense <<-RUBY
          RSpec.describe BA::Subject::Action do
            subject(:action) { described_class.new(performer: current_role) }
                               ^^^^^^^^^^^^^^^ Use `.as(performer)` instead of passing performer to the initializer
          end
        RUBY

        expect_correction <<-RUBY
          RSpec.describe BA::Subject::Action do
            subject(:action) { described_class.as(current_role).new() }
          end
        RUBY
      end
    end
  end

  context 'when performer is not passed to the initializer' do
    it { expect_no_offenses 'BA::Subject::Action.as_system.new(other: parameter)' }
  end

  context 'when performer is passed to the initializer' do
    context 'when performer is given as {expression}' do
      context 'when performer is a method chain' do
        it do
          expect_offense <<-RUBY
            BA::Subject::Action.new(other: parameter, performer: subject.author)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `.as(performer)` instead of passing performer to the initializer
          RUBY

          expect_correction <<-RUBY
            BA::Subject::Action.as(subject.author).new(other: parameter)
          RUBY
        end
      end

      context 'when performer is a single method call or a variable' do
        it do
          expect_offense <<-RUBY
            BA::Subject::Action.new(document, performer: performer).perform!
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `.as(performer)` instead of passing performer to the initializer
          RUBY

          expect_correction <<-RUBY
            BA::Subject::Action.as(performer).new(document).perform!
          RUBY
        end
      end
    end

    context 'when subject is the first parameter and performer is the second parameter' do
      it do
        expect_offense <<-RUBY
          BA::Subject::Action.new(subject, performer: object.message)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `.as(performer)` instead of passing performer to the initializer
        RUBY

        expect_correction <<-RUBY
          BA::Subject::Action.as(object.message).new(subject)
        RUBY
      end

      it do
        expect_offense <<-RUBY
          BA::Subject::Action.new(subject, performer: ::Object.new).perform!
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `.as(performer)` instead of passing performer to the initializer
        RUBY

        expect_correction <<-RUBY
          BA::Subject::Action.as(::Object.new).new(subject).perform!
        RUBY
      end
    end

    context 'when there are other method calls before new' do
      it do
        expect_offense <<-RUBY
          BA::Subject::Action.modal.new(performer: performer)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `.as(performer)` instead of passing performer to the initializer
        RUBY
      end

      it do
        expect_offense <<-RUBY
          BA::Subject::Action.for(step_type).new(performer: performer)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `.as(performer)` instead of passing performer to the initializer
        RUBY
      end

      it do
        expect_offense <<-RUBY
          BA::Subject::Action.modal.new(subject.company, performer: action.performer)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `.as(performer)` instead of passing performer to the initializer
        RUBY
      end
    end

    context 'when multi-line initializer' do
      context 'with other performer' do
        it do
          expect_offense <<-RUBY
            BA::Subject::Action.new(subject,
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `.as(performer)` instead of passing performer to the initializer
              performer: performer,
              other_param: param)
          RUBY

          expect_correction <<-RUBY
            BA::Subject::Action.as(performer).new(subject,
              other_param: param)
          RUBY
        end
      end

      context 'with other performer' do
        it do
          expect_offense <<-RUBY
            BA::Subject::Action.new(subject,
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `.as(performer)` instead of passing performer to the initializer
              performer: performer,
              other_param: param)
          RUBY

          expect_correction <<-RUBY
            BA::Subject::Action.as(performer).new(subject,
              other_param: param)
          RUBY
        end
      end

      context 'with multiple params' do
        it do
          expect_offense <<-RUBY
            BA::Subject::Action.new(subject,
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `.as(performer)` instead of passing performer to the initializer
              performer: performer,
              first: param,
              second: param
            )
          RUBY

          expect_correction <<-RUBY
            BA::Subject::Action.as(performer).new(subject,
              first: param,
              second: param
            )
          RUBY
        end
      end
    end
  end
end
