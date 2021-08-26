require 'active_data/model'
require 'active_data/model/primary'
require 'active_data/model/lifecycle'
require 'active_data/model/associations'

require 'granite/translations'
require 'granite/represents'
require 'granite/assign_data'

module Granite
  # Base included in Granite::Action, but also used by ActiveData when building data objects (e.g. when using
  # embeds_many)
  module Base
    extend ActiveSupport::Concern

    include ActiveSupport::Callbacks
    include ActiveData::Model
    include ActiveData::Model::Representation
    include ActiveData::Model::Dirty
    include ActiveData::Model::Associations
    include ActiveData::Model::Primary
    include ActiveModel::Validations::Callbacks

    include Granite::Util
    include Granite::AssignData
    include Granite::Represents
  end
end
