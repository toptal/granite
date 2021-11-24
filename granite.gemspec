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

  s.add_runtime_dependency 'actionpack', '>= 5.1', '< 7'
  s.add_runtime_dependency 'active_data', '~> 1.1.5'
  s.add_runtime_dependency 'activesupport', '>= 5.1', '< 7'
  s.add_runtime_dependency 'memoist', '~> 0.16'
end
