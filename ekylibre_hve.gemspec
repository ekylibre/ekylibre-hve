$:.push File.expand_path('../lib', __FILE__)

require 'ekylibre_hve/version'

Gem::Specification.new do |s|
  s.name        = 'ekylibre_hve'
  s.version     = EkylibreHve::VERSION
  s.authors     = ['Ekylibre developers']
  s.email       = ['dev@ekylibre.com']
  s.summary     = 'HVE3 audit plugin for Ekylibre'
  s.description = 'Computes the HVE3 (Haute Valeur Environnementale) audit score from Ekylibre data and exports the official Certibase Excel grid.'
  s.license     = 'AGPL-3.0-only'

  s.files = Dir['{app,config,db,lib}/**/*', 'LICENSE.md', 'README.md']
  s.require_path = ['lib']
  s.test_files   = Dir['test/**/*']

  s.required_ruby_version = '>= 2.6.0'

  s.add_dependency 'rails', '~> 5.2'

  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'rubocop-rails'
end
