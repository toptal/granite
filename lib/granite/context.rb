require 'singleton'

module Granite
  class Context
    include Singleton

    def view_context
      Thread.current[:granite_view_context]
    end

    def view_context=(context)
      Thread.current[:granite_view_context] = context
    end

    def with_view_context(context)
      old_view_context = view_context
      self.view_context = context

      yield
    ensure
      self.view_context = old_view_context
    end

    def self.delegated
      public_instance_methods - superclass.public_instance_methods - Singleton.public_instance_methods
    end
  end
end
