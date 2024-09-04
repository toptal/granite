require 'tzinfo'
require 'active_support'
require 'active_support/deprecation'
require 'active_support/core_ext'
require 'active_support/concern'
require 'singleton'

require 'active_model'

require 'granite/form/version'
require 'granite/form/util'
require 'granite/form/errors'
require 'granite/form/extensions'
require 'granite/form/undefined_class'
require 'granite/form/types'
require 'granite/form/config'
require 'granite/form/railtie' if defined? Rails
require 'granite/form/model'
require 'granite/form/model/associations/persistence_adapters/base'
require 'granite/form/model/associations/persistence_adapters/active_record'

module Granite
  module Form
    def self.config
      Granite::Form::Config.instance
    end

    singleton_class.delegate(*Granite::Form::Config.delegated, to: :config)

    config.types = {
      'Object' => Types::Object,
      'String' => Types::String,
      'Array' => Types::Array,
      'Date' => Types::Date,
      'DateTime' => Types::DateTime,
      'Time' => Types::Time,
      'ActiveSupport::TimeZone' => Types::ActiveSupport::TimeZone,
      'BigDecimal' => Types::BigDecimal,
      'Float' => Types::Float,
      'Integer' => Types::Integer,
      'Boolean' => Types::Boolean,
      'Granite::Form::UUID' => Types::UUID
    }
  end
end

require 'granite/form/base'

Granite::Form.base_class = Granite::Form::Base

ActiveSupport.on_load :action_controller do
  Granite::Form.config.types['Hash'] = Granite::Form::Types::HashWithActionControllerParameters
end

ActiveSupport.on_load :active_record do
  require 'granite/form/active_record/associations'
  require 'granite/form/active_record/nested_attributes'

  include Granite::Form::ActiveRecord::Associations
  singleton_class.prepend Granite::Form::ActiveRecord::NestedAttributes

  def self.granite_persistence_adapter
    Granite::Form::Model::Associations::PersistenceAdapters::ActiveRecord
  end
end
