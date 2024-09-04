module Granite
  module Form
    module Model
      module Conventions
        extend ActiveSupport::Concern

        included do
          attr_reader :embedder

          delegate :logger, to: Granite::Form
          self.include_root_in_json = Granite::Form.include_root_in_json
        end

        def persisted?
          false
        end

        def new_record?
          !persisted?
        end

        alias new_object? new_record?

        module ClassMethods
          def i18n_scope
            Granite::Form.i18n_scope
          end

          def to_ary
            nil
          end

          def primary_name
            nil
          end
        end
      end
    end
  end
end
