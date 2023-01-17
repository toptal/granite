require 'granite/form/model'
require 'granite/form/model/primary'
require 'granite/form/model/associations'

require 'granite/translations'
require 'granite/assign_data'

module Granite
  # Base included in Granite::Action, but also used by Granite::Form when building data objects (e.g. when using
  # embeds_many)
  module Base
    extend ActiveSupport::Concern
    extend ActiveModel::Callbacks

    include Granite::Form::Model
    include Granite::Form::Model::Representation
    include Granite::Form::Model::Dirty
    include Granite::Form::Model::Associations
    include Granite::Form::Model::Primary
    include ActiveModel::Validations::Callbacks

    include Granite::AssignData
  end
end
