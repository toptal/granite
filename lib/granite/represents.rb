require 'granite/represents/reflection'

module Granite
  module Represents
    extend ActiveSupport::Concern

    module ClassMethods
      private

      def represents(*fields, &block)
        options = fields.extract_options!.symbolize_keys

        fields.each do |field|
          add_attribute Granite::Represents::Reflection, field, options, &block

          assign_data { attribute(field).sync if attribute(field).changed? }
        end
      end
    end
  end
end
