require 'granite/action/error'
require 'granite/action/policies/any_strategy'
require 'granite/action/policies/always_allow_strategy'
require 'granite/action/policies/required_performer_strategy'

module Granite
  class Action
    class NotAllowedError < Error
      def initialize(action)
        performer_id = "##{action.performer.id}" if action.performer.respond_to?(:id) && action.performer.id.present?

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
        # The simplies policy. Takes block and executes it returning
        # boolean result. Multiple policies are reduced with ||
        #
        #   class Action < Granite::Action
        #     allow_if { performer.is_a?(Recruiter) }
        #     allow_if { performer.is_a?(AdvancedRecruiter) }
        #   end
        #
        # The first argument in block is a current action performer,
        # so it is possible to use a short-cut performer methods:
        #
        #   class Action < Granite::Action
        #     allow_if(&:staff?)
        #   end
        #
        def allow_if(&block)
          self._policies += [block]
        end

        def allow_self
          allow_if { performer == subject }
        end
      end

      def try_perform!(*, **)
        authorize!
        super
      end

      def perform(*, **)
        authorize!
        super
      end

      def perform!(*, **)
        authorize!
        super
      end

      # Returns true if any of defined policies returns true
      #
      def allowed?
        @allowed = _policies_strategy.allowed?(self) unless instance_variable_defined?(:@allowed)
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
