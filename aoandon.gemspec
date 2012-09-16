# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aoandon/version'

Gem::Specification.new do |gem|
  gem.name          = 'aoandon'
  gem.version       = Aoandon::VERSION
  gem.authors       = ['Cyril Wack']
  gem.email         = ['contact@cyril.io']
  gem.description   = %q{Aoandon (青行燈) is a minimalist network intrusion detection system (NIDS).}
  gem.summary       = %q{Minimalist network intrusion detection system (NIDS).}
  gem.homepage      = 'https://github.com/cyril/aoandon'
  gem.license       = 'MIT'
  gem.bindir        = 'bin'
  gem.add_dependency 'pcap'
  gem.files         = `git ls-files`.split($/).reject {|f| f == 'blue-andon-creature.jpg' }
  gem.executables   = gem.files.grep(%r{^bin/}).map {|f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib', 'config']
end
