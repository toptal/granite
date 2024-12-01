%w[6.1 7.0 7.1 7.2 8.0].each do |version|
  appraise "rails.#{version}" do
    gem 'actionpack', "~> #{version}.0"
    gem 'activesupport', "~> #{version}.0"
    gem 'activerecord', "~> #{version}.0"
  end
end
