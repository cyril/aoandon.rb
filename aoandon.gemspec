Gem::Specification.new do |spec|
  spec.name          = 'aoandon'
  spec.version       = File.read('VERSION.semver')
  spec.authors       = ['Cyril Wack']
  spec.email         = ['contact@cyril.io']
  spec.homepage      = 'https://github.com/cyril/aoandon.rb'
  spec.summary       = %q{Minimalist network intrusion detection system (NIDS).}
  spec.description   = %q{Aoandon (青行燈) is a minimalist network intrusion detection system (NIDS).}
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) {|f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^test/})
  spec.require_paths = ['lib']

  spec.add_dependency 'ruby-pcap', '~> 0.7'

  spec.add_development_dependency 'bundler',  '~> 1.6'
  spec.add_development_dependency 'minitest', '~> 5'
  spec.add_development_dependency 'rake',     '~> 10'
end
