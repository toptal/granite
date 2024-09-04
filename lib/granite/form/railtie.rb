module Granite
  module Form
    class Railtie < Rails::Railtie
      initializer 'granite.logger', after: 'active_record.logger' do
        ActiveSupport.on_load(:active_record) { Granite::Form.logger ||= ActiveRecord::Base.logger }
      end
    end
  end
end
