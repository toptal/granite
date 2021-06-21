require 'granite/action/preconditions/base_precondition'
require 'granite/action/preconditions/embedded_precondition'
require 'granite/action/preconditions/object_precondition'

module Granite
  class Action
    # Conditions module is used to define preconditions for actions.
    # Each precondition is also defined as validation, so it always run
    # before action execution. Precondition name is by default
    # I18n key for +:base+ error, if precondition fails. Along with
    # preconditions question methods with the same names are created.
    #
    module Preconditions
      extend ActiveSupport::Concern

      class PreconditionsCollection
        include Enumerable

        delegate :each, to: :@preconditions

        def initialize(*preconditions)
          @preconditions = preconditions.flatten
        end

        def +(other)
          self.class.new(*@preconditions, other)
        end

        def execute!(context)
          @preconditions.each { |precondition| precondition.execute!(context) }
        end
      end

      included do
        class_attribute :_preconditions, instance_writer: false
        self._preconditions = PreconditionsCollection.new
      end

      module ClassMethods
        # Define preconditions for current action.
        #
        # @param options [Hash] hash with
        # @option message [String, Symbol] error message
        # @option group [Symbol] procondition group(s)
        # @param block [Block] which returns truthy value when precondition
        #   should pass.
        def precondition(*args, &block)
          options = args.extract_options!
          if block
            add_precondition(BasePrecondition, options, &block)
          elsif args.first.is_a?(Class)
            add_precondition(ObjectPrecondition, *args, options)
          else
            add_preconditions_hash(*args, **options)
          end
        end

        private

        def klass(key)
          key = key.to_s.camelize
          Granite.precondition_namespaces.reduce(nil) do |memo, ns|
            memo || "#{ns.to_s.camelize}::#{key}Precondition".safe_constantize
          end || fail(NameError, "No precondition class for #{key}Precondition")
        end

        def add_preconditions_hash(*args, **options)
          common_options = options.extract!(:if, :unless, :desc, :description)
          args.each do |type|
            precondition common_options.merge(type => {})
          end
          options.each do |key, value|
            value = Array.wrap(value)
            precondition_options = value.extract_options!
            add_precondition(klass(key), *value, precondition_options.merge!(common_options))
          end
        end

        def add_precondition(klass, *args, &block)
          self._preconditions += klass.new(*args, &block)
        end
      end

      attr_reader :failed_preconditions

      def initialize(*)
        @failed_preconditions = []
        super
      end

      # Check if all preconditions are satisfied
      #
      # @return [Boolean] wheter all preconditions are satisfied
      def satisfy_preconditions?
        errors.clear
        failed_preconditions.clear
        run_preconditions!
      end

      # Adds passed error message and options to `errors` object
      def decline_with(*args)
        errors.add(:base, *args)
        failed_preconditions << args.first
      end

      private

      def run_preconditions!
        _preconditions.execute! self
        errors.empty?
      end

      def run_validations!
        run_preconditions! && super
      end
    end
  end
end
