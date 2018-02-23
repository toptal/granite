require 'granite/projector/controller_actions'
require 'granite/projector/error'
require 'granite/projector/helpers'
require 'granite/projector/translations'
require 'granite/performer_proxy'

module Granite
  class Projector
    include PerformerProxy
    include ControllerActions
    include Helpers
    include Translations

    singleton_class.__send__(:attr_accessor, :action_class)
    delegate :action_class, :projector_name, to: 'self.class'
    attr_reader :action

    def self.controller_class
      return Granite::Controller unless superclass.respond_to?(:controller_class)

      @controller_class ||= Class.new(superclass.controller_class).tap do |klass|
        klass.projector_class = self
      end
    end

    def self.projector_path
      @projector_path ||= name.remove(/Projector$/).underscore
    end

    def self.projector_name
      @projector_name ||= name.demodulize.remove(/Projector$/).underscore
    end

    def initialize(*args)
      @action = if args.first.is_a?(Granite::Action) # Temporary solutions for backwards compatibility.
                  args.first
                else
                  build_action(*args)
                end
    end

    private

    def build_action(*args)
      action_class.as(self.class.proxy_performer).new(*args)
    end
  end
end
