module Granite
  class Action
    # Documentation module is used to categorize Actions by domains and provide a short description of what Action does
    module Documentation
      extend ActiveSupport::Concern

      included do
        class_attribute :_domain, :_description
      end

      module ClassMethods
        # Use domain and description methods to provide information about what Action does and its domain:
        #
        # class Action < Granite::Action
        #   domain 'library'
        #   description 'Allows to borrow a book'
        # end

        # Assign action to domain
        # @param domain name [String]
        def domain(domain)
          self._domain = domain
        end

        # Provide a short description to the action
        # @param description name [String]
        def description(description)
          self._description = description
        end

        alias desc description
      end
    end
  end
end
