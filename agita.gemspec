require_relative 'lib/agita/version'

Gem::Specification.new do |s|
  s.name             = 'agita'
  s.version          = Agita::VERSION
  s.summary          = 'Git commands / workflow helper.'
  s.description      = 'Git commands / workflow helper.'
  s.email            = 'fabio.ornellas@gmail.com'
  s.homepage         = 'https://github.com/fornellas/agita'
  s.license          = 'GPL-3.0'
  s.authors          = ['Fabio Pugliese Ornellas']
  s.files            = Dir.glob('lib/**/*').keep_if{|p| not File.directory? p}
  s.extra_rdoc_files = ['README.md']
  s.rdoc_options     = %w{--main README.md lib/ README.md}
  s.add_development_dependency 'rake', '~>10.4'
  s.add_development_dependency 'gem_polisher', '~>0.4', '>=0.4.8'
  s.add_development_dependency 'rspec', '~>3.4'
  s.add_development_dependency 'simplecov', '~>0.11', '>=0.11.1'
end
