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
  gem.executables   = Dir['bin/*'].map {|f| File.basename(f) }
  gem.require_paths = ['lib']

  gem.add_dependency 'feedzirra', '~> 0.7.0'
  gem.add_dependency 'mail', '~> 2.5.4'
  gem.add_dependency 'sanitize', '~> 2.1.0'
  gem.add_dependency 'reverse_markdown', '~> 0.6.0'
  gem.add_dependency 'thor', '~> 0.19.1'

  gem.add_development_dependency 'rspec', '~> 2.14.1'
  gem.add_development_dependency 'fuubar'
  gem.add_development_dependency 'pry'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'travis-lint'

  gem.post_install_message = %{\

Important changes since version 0.6.0:

* Each feed has its own history file. Please run the provided migration script
  to migrate your history before using feed2email: feed2email-migrate-history
  If you don't, feed2email will think it is run for the first time and will
  treat all entries as old (thus no email will be sent and you may miss some
  entries).

* `sender` is a required config option. Please update your config file
  (~/.feed2email/config.yml) to set it to an email address to send email from.

Important changes since version 0.8.0:

* Feed metadata is stored in the feed list (~/.feed2email/feeds.yml). Please run
  the provided migration script before using feed2email:
  `feed2email-migrate-feedlist` It is safe to remove any leftover feed meta
  files: rm ~/.feed2email/meta-*.yml

* A command-line interface is available. Running feed2email without any options
  will display some help text. To run it so that it processes your feed
  subscriptions (sending email etc.), issue: feed2email process

}
end
