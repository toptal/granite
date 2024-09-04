module Granite
  module Form
    class Error < StandardError
    end

    class NotFound < Error
    end

    # Backported from active_model 5
    class ValidationError < Error
      attr_reader :model

      def initialize(model)
        @model = model
        errors = @model.errors.full_messages.join(', ')
        super(I18n.t(:"#{@model.class.i18n_scope}.errors.messages.model_invalid",
                     errors: errors, default: :'errors.messages.model_invalid'))
      end
    end

    class AssociationTypeMismatch < Error
      def initialize(expected, got)
        super("Expected `#{expected}` (##{expected.object_id}), but got `#{got}` (##{got.object_id})")
      end
    end

    class ObjectNotFound < Error
      def initialize(object, association_name, record_id)
        primary_name = object.respond_to?(:_primary_name) ? object._primary_name : 'id'
        message = "Couldn't find #{object.class.reflect_on_association(association_name).klass.name}" \
                  "with #{primary_name} = #{record_id} for #{object.inspect}"
        super(message)
      end
    end

    class TooManyObjects < Error
      def initialize(limit, actual_size)
        super("Maximum #{limit} objects are allowed. Got #{actual_size} objects instead.")
      end
    end

    class UndefinedPrimaryAttribute < Error
      def initialize(klass, association_name)
        super(<<~MESSAGE)
          Undefined primary attribute for `#{association_name}` in #{klass}.
          It is required for embeds_many nested attributes proper operation.
          You can define this association as:

            embeds_many :#{association_name} do
              primary :attribute_name
            end
        MESSAGE
      end
    end

    class NormalizerMissing < NoMethodError
      def initialize(name)
        super(<<~MESSAGE)
          Could not find normalizer `:#{name}`
          You can define it with:

            Granite::Form.normalizer(:#{name}) do |value, options|
              # do some staff with value and options
            end
        MESSAGE
      end
    end

    class TypecasterMissing < NoMethodError
      def initialize(*classes)
        classes = classes.flatten
        super(<<~MESSAGE)
          Could not find typecaster for #{classes}
          You can define it with:

            Granite::Form.typecaster('#{classes.first}') do |value|
              # do some staff with value and options
            end
        MESSAGE
      end
    end

    class PersistenceAdapterMissing < NoMethodError
      def initialize(data_source)
        super(<<~MESSAGE)
          Could not find persistence adapter for #{data_source}
          You can define it with:

            class #{data_source}
              def self.granite_persistence_adapter
                #{data_source}GraniteFormPersistenceAdapter
              end
            end
        MESSAGE
      end
    end
  end
end
