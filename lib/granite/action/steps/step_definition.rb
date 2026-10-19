module Granite
  class Action
    module Steps
      # Step definition for class steps. Can be converted to step instance using {#to_step} method.
      class StepDefinition
        attr_reader :options

        def initialize(klass, required: true, attributes: {}, **options)
          @klass = klass
          @options = options
          @required = required
          @attribute_definitions = attributes
        end

        def to_step(parent, attributes)
          subject_association = @klass.reflect_on_association(:subject)
          subject = parent.public_send(subject_association.name) if subject_association
          @klass.with(parent.ctx).new(*subject, attributes.merge(evaluated_attributes(parent)))
        end

        def perform_with
          @required ? :perform! : :try_perform!
        end

        def evaluated_attributes(parent)
          @attribute_definitions.to_h { |key, value| [key, parent.evaluate(value)] }
        end
      end
    end
  end
end
