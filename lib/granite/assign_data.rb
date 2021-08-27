module Granite
  module AssignData
    DataAssignment = Struct.new(:method, :options)

    extend ActiveSupport::Concern

    included do
      class_attribute :data_assignments
      self.data_assignments = []

      alias_method :only_run_validations!, :run_validations!
      protected :only_run_validations! # rubocop:disable Style/AccessModifierDeclarations
    end

    module ClassMethods
      # Defines a callback to call when assigning data from business action to model.
      # @param methods [Array<Symbol>] list of methods to call
      # @param block [Proc] a block to call
      # @option options [Symbol, Proc, Object] :if call methods/block if this condition evaluates to true
      # @option options [Symbol, Proc, Object] :unless call method/block unless this condition evaluates to true
      def assign_data(*methods, **options, &block)
        self.data_assignments += methods.map { |method| DataAssignment.new(method, options) }
        self.data_assignments += [DataAssignment.new(block, options)] if block
      end
    end

    protected

    def assign_data
      data_assignments.each { |assignment| evaluate(assignment.method) if conditions_satisfied?(**assignment.options) }
    end

    private

    def run_validations!
      assign_data
      super
    end
  end
end
