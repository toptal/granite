module Granite
  module Form
    module Types
      class Collection < HasSubtype
        def prepare(value)
          ::Array.wrap(value).map { |v| subtype_definition.prepare(v) }
        end
      end
    end
  end
end
