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
  s.required_ruby_version = '>= 2.6'

  s.add_runtime_dependency 'actionpack', '>= 6.0', '< 8.1'
  s.add_runtime_dependency 'activesupport', '>= 6.0', '< 7.2'
  s.add_runtime_dependency 'granite-form', '>= 0.3.0'
  s.add_runtime_dependency 'memoist', '~> 0.16'
  s.add_runtime_dependency 'ruby2_keywords', '~> 0.0.5'

  s.add_development_dependency 'activerecord'
  s.add_development_dependency 'appraisal'
  s.add_development_dependency 'bump'
  s.add_development_dependency 'fuubar', '~> 2.0'
  s.add_development_dependency 'pg', '< 2'
  s.add_development_dependency 'pry-byebug'
  s.add_development_dependency 'rspec', '~> 3.12'
  s.add_development_dependency 'rspec-activemodel-mocks', '~> 1.0'
  s.add_development_dependency 'rspec-collection_matchers', '~> 1.1'
  s.add_development_dependency 'rspec-its', '~> 1.2 '
  s.add_development_dependency 'rspec_junit_formatter', '~> 0.2'
  s.add_development_dependency 'rspec-rails', '~> 6.0'
  s.add_development_dependency 'rubocop', '~> 1.65.1'
  s.add_development_dependency 'rubocop-rails', '~> 2.25.0'
  s.add_development_dependency 'rubocop-rspec', '~> 3.0.1'
  s.add_development_dependency 'rubocop-rspec_rails', '~> 2.30'
  s.add_development_dependency 'simplecov', '~> 0.15'

  s.metadata['rubygems_mfa_required'] = 'true'
end
