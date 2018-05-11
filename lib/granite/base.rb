require 'active_data/model'
require 'active_data/model/primary'
require 'active_data/model/lifecycle'
require 'active_data/model/associations'

require 'granite/translations'
require 'granite/represents'

module Granite
  module Base
    extend ActiveSupport::Concern

    include ActiveSupport::Callbacks
    include ActiveData::Model
    include ActiveData::Model::Representation
    include ActiveData::Model::Dirty
    include ActiveData::Model::Associations
    include ActiveData::Model::Primary
    include ActiveModel::Validations::Callbacks

    include Granite::Translations
    include Granite::Represents
  end
end
