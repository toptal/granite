require 'rails/all'

class ApplicationController < ActionController::Base
  rescue_from 'Granite::Action::NotAllowedError' do |exception|
    render plain: exception.to_s, status: :forbidden
  end
end

class GraniteApplication < Rails::Application
end

Rails.application = GraniteApplication.new
Rails.application.paths['config/database'] << File.expand_path('database.yml', __dir__)
if Rails.version > '7.1'
  Rails.application.config.secret_key_base = '1234567890'
else
  Rails.application.secrets.secret_key_base = '1234567890'
end
Rails.application.config.hosts = 'www.example.com'
Rails.application.routes_reloader.route_sets << Rails.application.routes
Rails.configuration.eager_load = false
Rails.application.initialize!
