require 'singleton'

module Granite
  module Form
    class UndefinedClass
      include Singleton
    end

    UNDEFINED = UndefinedClass.instance.freeze
  end
end
