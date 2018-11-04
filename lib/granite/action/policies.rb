require 'granite/action/error'
require 'granite/action/policies/any_strategy'
require 'granite/action/policies/always_allow_strategy'
require 'granite/action/policies/required_performer_strategy'

module Granite
  class Action
    class NotAllowedError < Error
      def initialize(action)
        if action.performer.respond_to?(:id) && action.performer.id.present?
          performer_id = "##{action.performer.id}"
        end

        super("#{action.class} action is not allowed " \
              "for #{action.performer.class}#{performer_id}", action)
      end
    end

    # Policies module used for abilities definition. Basically
    # policies are defined as blocks which are executed in action
    # instance context, so performer, object and all the attributes
    # are available inside the block.
    #
    # By default action is allowed to be performed only by default performer.
    #
    module Policies
      extend ActiveSupport::Concern

      included do
        class_attribute :_policies, :_policies_strategy, instance_writer: false
        self._policies = []
        self._policies_strategy = AnyStrategy
      end

      module ClassMethods
        # The simplest policy. Takes either a symbol or a block and executes it
        # returning boolean result. Multiple policies are reduced with ||
        #
        #   class Action < Granite::Action
        #     allow_if { performer.is_a?(Recruiter) }
        #     allow_if { performer.is_a?(AdvancedRecruiter) }
        #     allow_if :staff?
        #   end
        #
        # If symbol is passed, an instance method with the same name is executed.
        # If block is passed, the first argument of the block is the current action
        # performer, so it is possible to use a short-cut performer methods:
        #
        #   class Action < Granite::Action
        #     allow_if(&:staff?)
        #   end
        #
        def allow_if(method_name = nil, &block)
          policy = method_name ? proc { __send__(method_name) } : block
          self._policies += [policy]
        end

        def allow_self
          allow_if { performer == subject }
        end
      end

      def try_perform!(*)
        authorize!
        super
      end

      def perform(*)
        authorize!
        super
      end

      def perform!(*)
        authorize!
        super
      end

      # Returns true if any of defined policies returns true
      #
      def allowed?
        unless instance_variable_defined?(:@allowed)
          @allowed = _policies_strategy.allowed?(self)
        end
        @allowed
      end

      # Raises Granite::Action::NotAllowedError if action is not allowed
      #
      def authorize!
        fail Granite::Action::NotAllowedError, self unless allowed?

        self
      end
    end
  end
end
