module Granite
  class Action
    module AssignData
      extend ActiveSupport::Concern

      included do
        class_attribute :data_assignments
        self.data_assignments = []
      end

      module ClassMethods
        def assign_data(*methods, &block)
          self.data_assignments += [*methods, *block]
        end
      end

      private

      def run_validations!
        assign_data && super
      end

      def assign_data
        data_assignments.each(&method(:evaluate))
      end
    end
  end
end
