require_relative 'application_record'

class User < ApplicationRecord
  alias_attribute :sign_ins, :sign_in_count
end
