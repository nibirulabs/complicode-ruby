# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'complicode/version'

Gem::Specification.new do |spec|
  spec.name          = 'complicode'
  spec.version       = Complicode::VERSION
  spec.authors       = ['Sergio Tapia', 'Pablo Crivella']
  spec.email         = ['sergiotapia@outlook.com', 'pablocrivella@gmail.com']
  spec.summary       = 'Complicode! A needlessly complicated code generator!'
  spec.description   = %q(Generador de codigo de control para facturas dentro del Servicio Nacional de Impuestos de Bolivia.)
  spec.homepage      = 'https://github.com/mobilebits-bolivia/complicode-ruby'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'verhoeff', '~> 2.1'
  spec.add_dependency 'radix', '~> 2.2'
  spec.add_dependency 'ruby-rc4', '~> 0.1.5'
  spec.add_dependency 'virtus', '~> 1.0'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake', '~> 10.4'
  spec.add_development_dependency 'rspec', '~> 3.2'
  spec.add_development_dependency 'pry', '~> 0.10.1'
  spec.add_development_dependency 'pry-byebug', '~> 3.1'
  spec.add_development_dependency 'smarter_csv', '~> 1.0'
end
