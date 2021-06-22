require 'action_dispatch/routing'

module Granite
  class Projector
    module ControllerActions
      extend ActiveSupport::Concern

      included do
        class_attribute :controller_actions
        self.controller_actions = {}

        ActionDispatch::Routing::HTTP_METHODS.each do |method|
          define_singleton_method method do |name, options = {}, &block|
            action(name, options.merge(method: method), &block)
          end
        end
      end

      module ClassMethods
        def action(name, options = {}, &block)
          if block
            self.controller_actions = controller_actions.merge(name.to_sym => options)
            controller_class.__send__(:define_method, name, &block)
            class_eval <<-METHOD, __FILE__, __LINE__ + 1
              def #{name}_url(options = {})
                action_url(:#{name}, **options.symbolize_keys)
              end

              def #{name}_path(options = {})
                action_path(:#{name}, **options.symbolize_keys)
              end
            METHOD
          else
            controller_actions[name.to_sym]
          end
        end

        def action_for(http_method, action)
          controller_actions.find do |controller_action, controller_action_options|
            controller_action_options.fetch(:as, controller_action).to_s == action &&
              Array(controller_action_options.fetch(:method)).include?(http_method)
          end&.first
        end
      end
    end
  end
end
