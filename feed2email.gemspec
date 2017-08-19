require File.expand_path('../lib/feed2email/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = 'feed2email'
  gem.version       = Feed2Email::VERSION
  gem.author        = 'Angelos Orfanakos'
  gem.email         = 'me@agorf.gr'
  gem.homepage      = 'https://github.com/agorf/feed2email'
  gem.summary       = 'RSS/Atom feed updates in your email'
  gem.license       = 'MIT'

  gem.files         = Dir['lib/**/*.rb', 'bin/*', '*.md', 'LICENSE.txt']
  gem.executables   = Dir['bin/*'].map {|f| File.basename(f) }
  gem.require_paths = ['lib']

  gem.required_ruby_version = '>= 2.1.8'

  gem.add_dependency 'feedzirra', '~> 0.7.0'
  gem.add_dependency 'mail', '~> 2.5.4'
  gem.add_dependency 'sanitize', '~> 2.1.0'
  gem.add_dependency 'reverse_markdown', '~> 0.6.0'
  gem.add_dependency 'thor', '~> 0.19.1'
  gem.add_dependency 'nokogiri', '~> 1.6.5'
  gem.add_dependency 'sequel', '~> 4.18.0'
  gem.add_dependency 'sqlite3', '~> 1.3.10'

  gem.add_development_dependency 'rspec', '~> 3.4.0'
  gem.add_development_dependency 'pry'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'travis-lint'
  gem.add_development_dependency 'webmock', '~> 1.22.3'
  gem.add_development_dependency 'simplecov', '~> 0.15.0'

  gem.post_install_message = %{\
* Since version 0.12.0, the config directory of feed2email is
  `~/.config/feed2email/` so you need to move it before running feed2email:

  `mkdir ~/.config/ && mv ~/.feed2email/ ~/.config/feed2email/`

* Since version 0.9.0, the default send method is `file` which writes emails to
  a file under `~/Mail/`. To change it, edit your config file (`feed2email
  config`) and set `send_method` to `sendmail` or `smtp`.

* Since version 0.8.0, a command-line interface is available. Running feed2email
  without any arguments will display some help text. To have feed2email process
  your feed list, issue `feed2email process`

  Don't forget to update any cron jobs too!

}
end
