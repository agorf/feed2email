require File.expand_path('../lib/feed2email/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = 'feed2email'
  gem.version       = Feed2Email::VERSION
  gem.platform      = Gem::Platform::RUBY
  gem.author        = 'Aggelos Orfanakos'
  gem.email         = 'me@agorf.gr'
  gem.homepage      = 'https://github.com/agorf/feed2email'
  gem.summary       = 'RSS/Atom feed updates in your email'
  gem.description   = gem.summary
  gem.license       = 'MIT'

  gem.files         = Dir['lib/**/*.rb', 'bin/*', '*.md', 'LICENSE.txt']
  gem.test_files    = Dir['spec/**/*.rb']
  gem.executables   = ['feed2email']
  gem.require_paths = ['lib']

  gem.add_dependency 'feedzirra', '~> 0.7.0'
  gem.add_dependency 'mail', '~> 2.5.4'
  gem.add_dependency 'sanitize', '~> 2.1.0'

  gem.add_development_dependency 'rspec', '~> 2.14.1'
  gem.add_development_dependency 'pry'
end
