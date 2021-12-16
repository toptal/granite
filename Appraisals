%w[5.1 5.2 6.0 6.1 7.0].each do |version|
  appraise "rails.#{version}" do
    gem 'actionpack', "~> #{version}.0"
    gem 'activesupport', "~> #{version}.0"
    gem 'activerecord', "~> #{version}.0"
  end
end
