module Granite
  module Form
    module Model
      module Primary
        extend ActiveSupport::Concern
        DEFAULT_PRIMARY_ATTRIBUTE_OPTIONS = lambda do
          {
            type: Granite::Form::UUID,
            default: -> { Granite::Form::UUID.random_create }
          }
        end

        included do
          class_attribute :_primary_name, instance_writer: false
          delegate :has_primary_attribute?, to: 'self.class'

          prepend PrependMethods
          alias_method :eql?, :==
        end

        module ClassMethods
          def primary(*args)
            options = args.extract_options!
            self._primary_name = (args.first.presence || Granite::Form.primary_attribute).to_s
            unless has_attribute?(_primary_name)
              options[:type] = args.second if args.second
              attribute _primary_name, options.presence || DEFAULT_PRIMARY_ATTRIBUTE_OPTIONS.call
            end
            alias_attribute :primary_attribute, _primary_name
          end

          alias primary_attribute primary

          def has_primary_attribute? # rubocop:disable Naming/PredicateName
            has_attribute? _primary_name
          end

          def primary_name
            _primary_name
          end
        end

        module PrependMethods
          def ==(other)
            if other.instance_of?(self.class) && has_primary_attribute?
              if primary_attribute
                primary_attribute == other.primary_attribute
              else
                object_id == other.object_id
              end
            else
              super(other)
            end
          end
        end
      end
    end
  end
end
