RSpec.describe Granite::Action::Projectors do
  before do
    stub_class(:first_projector, Granite::Projector)
    stub_class(:second_projector, Granite::Projector)
    stub_class(:third_projector, Granite::Projector)

    stub_class(:first_action, Granite::Action) do
      const_set('ZeroProjector', Class.new(Granite::Projector) do
        def value
          # :nocov: - as the class is overwritten with `projector :zero`
          13
          # :nocov:
        end
      end)
      projector :zero do
        def value
          31
        end
      end
      projector :first do
        def value
          42
        end
      end
      projector :other, class_name: 'SecondProjector'
      projector :overwritten_other, class_name: 'SecondProjector'
    end

    stub_class(:second_action, FirstAction) do
      projector :first do
        def value
          43
        end

        def will_be_overwritten
          # :nocov: - as the method is overwritten in second definition of `projector :first`
          13
          # :nocov:
        end
      end
      projector :third
      projector :first do
        def another_value
          666
        end

        def will_be_overwritten
          31
        end
      end
      projector :overwritten_other, class_name: 'ThirdProjector'
    end
  end

  describe '.projector_names' do
    specify { expect(FirstAction.projector_names).to match_array(%i[zero first other overwritten_other]) }
    specify { expect(SecondAction.projector_names).to match_array(%i[first third zero other overwritten_other]) }
  end

  describe '.#{projector_name}' do
    specify { expect(FirstAction.zero).to equal(FirstAction.zero) }
    specify { expect(FirstAction.new.zero.value).to eq(31) }

    specify { expect(FirstAction.zero).to be < Granite::Projector }
    specify { expect(FirstAction.zero).to eq(FirstAction::ZeroProjector) }

    specify { expect(FirstAction.first).to be < FirstProjector }
    specify { expect(FirstAction.first).to eq(FirstAction::FirstProjector) }
    specify { expect(FirstAction.new.first.value).to eq(42) }

    specify { expect(FirstAction.other).to be < SecondProjector }
    specify { expect(FirstAction.other).to eq(FirstAction::OtherProjector) }

    specify { expect(FirstAction.overwritten_other).to be < SecondProjector }
    specify { expect(FirstAction.overwritten_other).to eq(FirstAction::OverwrittenOtherProjector) }

    specify { expect(SecondAction.first).to be < FirstAction::FirstProjector }
    specify { expect(SecondAction.first).to eq(SecondAction::FirstProjector) }
    specify { expect(SecondAction.new.first.value).to eq(43) }
    specify { expect(SecondAction.new.first.another_value).to eq(666) }
    specify { expect(SecondAction.new.first.will_be_overwritten).to eq(31) }

    specify { expect(SecondAction.other).to be < FirstAction::OtherProjector }
    specify { expect(SecondAction.other).to eq(SecondAction::OtherProjector) }

    specify { expect(SecondAction.overwritten_other).to be < ThirdProjector }
    specify { expect(SecondAction.overwritten_other).to eq(SecondAction::OverwrittenOtherProjector) }

    specify { expect(SecondAction.third).to be < ThirdProjector }
    specify { expect(SecondAction.third).to eq(SecondAction::ThirdProjector) }

    specify { expect(FirstAction.first.action_class).to eq(FirstAction) }
    specify { expect(FirstAction.other.action_class).to eq(FirstAction) }
    specify { expect(SecondAction.first.action_class).to eq(SecondAction) }
    specify { expect(SecondAction.other.action_class).to eq(SecondAction) }
    specify { expect(SecondAction.third.action_class).to eq(SecondAction) }
  end

  describe '##{projector_name}' do
    specify { expect(FirstAction.new.first).to be_a FirstAction::FirstProjector }
    specify { expect(FirstAction.new.other).to be_a FirstAction::OtherProjector }
    specify { expect(FirstAction.new.overwritten_other).to be_a FirstAction::OverwrittenOtherProjector }

    specify { expect(SecondAction.new.first).to be_a SecondAction::FirstProjector }
    specify { expect(SecondAction.new.other).to be_a SecondAction::OtherProjector }
    specify { expect(SecondAction.new.third).to be_a SecondAction::ThirdProjector }
    specify { expect(SecondAction.new.overwritten_other).to be_a SecondAction::OverwrittenOtherProjector }
  end
end
