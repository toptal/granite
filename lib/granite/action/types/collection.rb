module Granite
  class Action
    module Types
      class Collection
        attr_reader :subtype

        def initialize(subtype)
          @subtype = subtype
        end
      end
    end
  end
end
