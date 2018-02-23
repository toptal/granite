require 'granite/action/represents/reflection'

module Granite
  class Action
    module Represents
      extend ActiveSupport::Concern

      module ClassMethods
        private

        def represents(*fields, &block)
          options = fields.extract_options!.symbolize_keys

          fields.each do |field|
            add_attribute Granite::Action::Represents::Reflection, field, options, &block

            before_validation do
              attribute(field).sync if __send__ "#{field}_changed?"
              true
            end
          end
        end
      end
    end
  end
end
