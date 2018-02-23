require 'granite/action/represents/attribute'

module Granite
  class Action
    module Represents
      class Reflection < ActiveData::Model::Attributes::Reflections::Represents
        class << self
          def attribute_class
            @attribute_class ||= Granite::Action::Represents::Attribute
          end
        end
      end
    end
  end
end
