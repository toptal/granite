require 'singleton'
require 'active_support/core_ext/object/try'

module Granite
  class Config
    include Singleton

    attr_accessor :base_controller
    attr_writer :precondition_namespaces

    def base_controller_class
      base_controller&.constantize || ActionController::Base
    end

    def precondition_namespaces
      @precondition_namespaces ||= %w[Granite::Action::Preconditions]
    end

    def self.delegated
      public_instance_methods - superclass.public_instance_methods - Singleton.public_instance_methods
    end
  end
end
