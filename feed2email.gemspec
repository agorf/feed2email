require 'date'

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'feed2email/version'

Gem::Specification.new do |gem|
  gem.name          = 'feed2email'
  gem.version       = Feed2Email::VERSION

  gem.authors       = ['Aggelos Orfanakos']
  gem.date          = Date.today
  gem.email         = ['agorf@agorf.gr']
  gem.homepage      = 'http://github.com/agorf/feed2email'

  gem.description   = %q{RSS/Atom feed updates in your email}
  gem.summary       = gem.description

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map {|f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_dependency 'feedzirra'
  gem.add_dependency 'mail'
end
