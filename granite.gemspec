# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'granite/version'

Gem::Specification.new do |s|
  s.name        = 'granite'
  s.version     = Granite::VERSION
  s.homepage    = 'https://github.com/toptal/granite'
  s.authors     = ['Toptal Engineering']
  s.summary     = 'Another business actions architecture for Rails apps'
  s.files       = `git ls-files`.split("\n").grep(/\A(app|lib|config|LICENSE)/)
  s.license     = 'MIT'
  s.required_ruby_version = '>= 2.5'

  s.add_runtime_dependency 'actionpack', '>= 5.1', '< 7.1'
  s.add_runtime_dependency 'active_data', '~> 1.2.0'
  s.add_runtime_dependency 'activesupport', '>= 5.1', '< 7.1'
  s.add_runtime_dependency 'memoist', '~> 0.16'
  s.add_runtime_dependency 'ruby2_keywords', '~> 0.0.5'

  s.add_development_dependency 'activerecord'
  s.add_development_dependency 'appraisal'
  s.add_development_dependency 'capybara', '~> 2.18'
  s.add_development_dependency 'fuubar', '~> 2.0'
  s.add_development_dependency 'pg', '< 2'
  s.add_development_dependency 'pry-byebug'
  s.add_development_dependency 'rspec', '~> 3.6'
  s.add_development_dependency 'rspec-activemodel-mocks', '~> 1.0'
  s.add_development_dependency 'rspec-collection_matchers', '~> 1.1'
  s.add_development_dependency 'rspec-its', '~> 1.2 '
  s.add_development_dependency 'rspec-rails', '~> 3.6'
  s.add_development_dependency 'rspec_junit_formatter', '~> 0.2'
  s.add_development_dependency 'rubocop', '~> 1.0'
  s.add_development_dependency 'rubocop-rails', '~> 2.13'
  s.add_development_dependency 'rubocop-rspec', '~> 2.8'
  s.add_development_dependency 'simplecov', '~> 0.15'
end
