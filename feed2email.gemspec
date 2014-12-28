require File.expand_path('../lib/feed2email/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = 'feed2email'
  gem.version       = Feed2Email::VERSION
  gem.author        = 'Aggelos Orfanakos'
  gem.email         = 'me@agorf.gr'
  gem.homepage      = 'https://github.com/agorf/feed2email'
  gem.summary       = 'RSS/Atom feed updates in your email'
  gem.license       = 'MIT'

  gem.files         = Dir['lib/**/*.rb', 'bin/*', '*.md', 'LICENSE.txt']
  gem.executables   = ['feed2email']
  gem.require_paths = ['lib']

  gem.add_dependency 'feedzirra', '~> 0.7.0'
  gem.add_dependency 'mail', '~> 2.5.4'
  gem.add_dependency 'sanitize', '~> 2.1.0'
  gem.add_dependency 'reverse_markdown', '~> 0.6.0'

  gem.add_development_dependency 'rspec', '~> 2.14.1'
  gem.add_development_dependency 'fuubar'
  gem.add_development_dependency 'pry'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'travis-lint'

  if Feed2Email::VERSION == '0.6.0'
    gem.post_install_message = %{\
WARNING! feed2email now maintains a separate history file per feed!

Please run the provided migration script `feed2email-migrate-history` before
using feed2email. This will split an existing single history file to many small
ones, one for each feed.

If history is not migrated, feed2email will think it is run for the first time
and will treat all entries as old (thus no email will be sent and you may miss
some entries).
}
  end
end
