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
  s.required_ruby_version = '>= 3.3'

  s.add_dependency 'actionpack', '>= 7.2'
  s.add_dependency 'activesupport', '>= 7.2'
  s.add_dependency 'granite-form'
  s.add_dependency 'memo_wise'

  s.add_development_dependency 'activerecord'
  s.add_development_dependency 'bump'
  s.add_development_dependency 'fuubar'
  s.add_development_dependency 'pg'
  s.add_development_dependency 'pry-byebug'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rspec-activemodel-mocks'
  s.add_development_dependency 'rspec-collection_matchers'
  s.add_development_dependency 'rspec-its'
  s.add_development_dependency 'rspec_junit_formatter'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'rubocop-rails'
  s.add_development_dependency 'rubocop-rspec'
  s.add_development_dependency 'rubocop-rspec_rails'
  s.add_development_dependency 'simplecov'

  s.metadata['rubygems_mfa_required'] = 'true'
end
