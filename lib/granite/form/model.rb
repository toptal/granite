require 'granite/form/model/conventions'
require 'granite/form/model/attributes'
require 'granite/form/model/validations'
require 'granite/form/model/scopes'
require 'granite/form/model/primary'
require 'granite/form/model/persistence'
require 'granite/form/model/associations'
require 'granite/form/model/representation'
require 'granite/form/model/dirty'

module Granite
  module Form
    module Model
      extend ActiveSupport::Concern

      included do
        extend ActiveModel::Naming
        extend ActiveModel::Translation

        include ActiveModel::Conversion
        include ActiveModel::Serialization
        include ActiveModel::Serializers::JSON

        include Util
        include Conventions
        include Attributes
        include Validations
      end
    end
  end
end
