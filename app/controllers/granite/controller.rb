require 'action_controller'

module Granite
  class Controller < Granite.base_controller_class
    include Controller::Translations
    helper Controller::Translations

    singleton_class.__send__(:attr_accessor, :projector_class)
    singleton_class.delegate :projector_path, :projector_name, :action_class, to: :projector_class
    delegate :projector_path, :projector_name, :action_class, :projector_class, to: 'self.class'

    abstract!

    before_action :authorize_action!

    def projector
      @projector ||=
        begin
          projector_class = action_class.public_send(projector_name)
          projector_class = projector_class.with(projector_context) if respond_to?(:projector_context, true)
          projector_class.new(projector_params)
        end
    end
    helper_method :projector

    delegate :action, to: :projector
    helper_method :action

    def self.local_prefixes
      [projector_path]
    end

    private

    def projector_params
      params
    end

    def authorize_action!
      action.authorize!
    end
  end
end
