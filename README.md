# feed2email [![Gem Version](https://badge.fury.io/rb/feed2email.svg)](http://badge.fury.io/rb/feed2email) [![Build Status](https://travis-ci.org/agorf/feed2email.png?branch=master)](https://travis-ci.org/agorf/feed2email)

feed2email is a [headless][] RSS/Atom feed aggregator that sends feed entries
via email. It was initially written as a replacement of [rss2email][] and aims
to be simple, fast and easy to use.

[headless]: http://en.wikipedia.org/wiki/Headless_software
[rss2email]: http://www.allthingsrss.com/rss2email/

## Features

* Command-line feed management (add, remove, enable/disable)
* Feed fetching caching (_Last-Modified_ and _ETag_ HTTP headers)
* [Feed autodiscovery](http://www.rssboard.org/rss-autodiscovery)
* [OPML][] import/export of feed subscriptions
* Email sending with SMTP, [Sendmail][]-compatible [MTA][] or by writing to a
  file
* _text/html_ and _text/plain_ (Markdown) multipart emails
* Temporary and permanent redirection support for feed URLs

[OPML]: http://en.wikipedia.org/wiki/OPML
[Sendmail]: http://en.wikipedia.org/wiki/Sendmail
[MTA]: http://en.wikipedia.org/wiki/Message_transfer_agent

## Installation

As a [gem][] from [RubyGems][]:

~~~ sh
gem install feed2email
~~~

If the above command fails due to missing headers, make sure the following
packages for [curb][] and [sqlite3][] gems are installed. For Debian, issue (as
root):

~~~ sh
apt-get install libcurl4-openssl-dev libsqlite3-dev
~~~

For the `backend` command to work, you need to have SQLite3 installed. For
Debian, issue (as root):

~~~ sh
apt-get install sqlite3
~~~

[gem]: http://rubygems.org/gems/feed2email
[RubyGems]: http://rubygems.org/
[curb]: https://rubygems.org/gems/curb
[sqlite3]: https://rubygems.org/gems/sqlite3

## Configuration

The config file is a [YAML][] file located at `~/.config/feed2email/config.yml`.
Each line contains a key-value pair and each key-value pair is separated with a
colon, e.g.: `foo: bar`

To edit the config file, use the `config` command:

~~~
$ # same as "f2e c"
$ feed2email config
~~~

**Note:** The command will fail if the `EDITOR` environmental variable is not
set.

[YAML]: http://en.wikipedia.org/wiki/YAML

### General options

* `recipient` (required) is the email address to send email to
* `sender` (required) is the email address to send email from (can be any)
* `send_method` (optional) is the method to send email with and can be `file`
  (default), `sendmail` or `smtp`
* `send_delay` (optional) is the number of seconds to wait between each email to
  avoid SMTP server throttling errors when `send_method` is `sendmail` or `smtp`
  (default is `10`; use `0` to disable)
* `max_entries` (optional) is the maximum number of entries to process per feed
  (default is `20`; use `false` for unlimited)
* `send_exceptions` (optional) specifies whether to send exceptions via email to
  `recipient` and can be `true` or `false` (default)

### Logging options

You can probably skip these as they are mostly useful for debugging.

* `log_path` (optional) is the _absolute_ path to the log file (default is
  `true` which logs to standard output; use `false` to disable logging)
* `log_level` (optional) is the logging verbosity level and can be `fatal`
  (least verbose), `error`, `warn`, `info` (default) or `debug` (most verbose)
* `log_shift_age` (optional) is the number of _old_ log files to keep or the
  frequency of rotation (`daily`, `weekly`, `monthly`; default is `0` so only
  the current log file is kept)
* `log_shift_size` (optional) is the maximum log file size in _megabytes_ and it
  only applies when `log_shift_age` is a number greater than zero (default is
  `1`)

### Sending options

#### SMTP

For this method you need to have access to an SMTP service. [Mailgun][] has a
free plan.

* `smtp_host` (required) is the SMTP service hostname to connect to
* `smtp_port` (required) is the SMTP service port to connect to
* `smtp_user` (required) is the username of your email account
* `smtp_pass` (required) is the password of your email account (see the warning
   below)
* `smtp_starttls` (optional) controls STARTTLS (default is `true`; can also be
  `false`)
* `smtp_auth` (optional) controls the authentication method (default is `login`;
   can also be `plain` or `cram_md5`)

**Warning:** Unless it has correct restricted permissions, anyone with access in
your system will be able to read `config.yml` and your password. To prevent
this, feed2email will not run and complain if it detects the wrong permissions.
To set the correct permissions, issue `chmod 600
~/.config/feed2email/config.yml`.

[Mailgun]: http://www.mailgun.com/

#### Sendmail

For this method you need to have [Sendmail][] or an [MTA][] with a
Sendmail-compatible interface (e.g. [msmtp][], [Postfix][]) set up and working
in your system.

* `sendmail_path` (optional) is the path to the Sendmail binary (default is
  `/usr/sbin/sendmail`)

[msmtp]: http://msmtp.sourceforge.net/
[Postfix]: http://en.wikipedia.org/wiki/Postfix_(software)

#### File

This method simply writes emails to a file (named after the `recipient` config
option) in a path that you specify.

* `mail_path` (optional) is the path to write emails in (default is `~/Mail/`)

## Use

### Add a feed

~~~
$ feed2email add https://github.com/agorf/feed2email/commits.atom
Added feed:   1 https://github.com/agorf/feed2email/commits.atom
$ # same as "feed2email add https://github.com/agorf.atom"
$ f2e a https://github.com/agorf.atom
Added feed:   2 https://github.com/agorf.atom
~~~

Passing the `--send-existing` option to `add` will send email for the
`max_entries` latest, existing entries when the feed is **processed for the
first time**. The default is to skip them.

#### Feed autodiscovery

Passing a website URL to the `add` command will have feed2email autodiscover any
feeds in that page that you are not already subscribed to:

~~~
$ f2e add http://www.rubyinside.com/
0: http://www.rubyinside.com/feed/ "Ruby Inside" (application/rss+xml)
Please enter a feed to subscribe to (or Ctrl-C to abort): [0] 0
Added feed:   3 http://www.rubyinside.com/feed/
$ f2e add http://thechangelog.com/137/
0: http://thechangelog.com/137/feed/ "The Changelog » #137: Better GitHub Issues with HuBoard and Ryan Rauh Comments Feed" (application/rss+xml)
1: http://thechangelog.com/feed/ "RSS 2.0 Feed" (application/rss+xml)
Please enter a feed to subscribe to (or Ctrl-C to abort): [0, 1] 1
Added feed:   4 http://thechangelog.com/feed/
$ # cancel autodiscovery by pressing Ctrl-C
$ f2e add http://thechangelog.com/137/
0: http://thechangelog.com/137/feed/ "The Changelog » #137: Better GitHub Issues with HuBoard and Ryan Rauh Comments Feed" (application/rss+xml)
Please enter a feed to subscribe to (or Ctrl-C to abort): [0] ^C
~~~

### List subscribed feeds

~~~
$ # same as "f2e l"
$ feed2email list
  1 https://github.com/agorf/feed2email/commits.atom
  2 https://github.com/agorf.atom
  3 http://www.rubyinside.com/feed/
  4 http://thechangelog.com/feed/

Subscribed to 4 feeds
~~~

### Enable/Disable a feed

A feed can be disabled so that it is not processed when `feed2email process`
runs with the `toggle` command:

~~~
$ # same as "f2e t 1"
$ feed2email toggle 1
Toggled feed:   1 DISABLED https://github.com/agorf/feed2email/commits.atom
~~~

It can be enabled with the `toggle` command again:

~~~
$ # same as "feed2email toggle 1"
$ f2e t 1
Toggled feed:   1 https://github.com/agorf/feed2email/commits.atom
~~~

### Remove a feed

A feed can also be removed from feed subscriptions permanently:

~~~
$ # same as "f2e r 1"
$ feed2email remove 1
Remove feed:   1 https://github.com/agorf/feed2email/commits.atom
Are you sure? [y, n] y
Removed
~~~

### Import/Export feeds

feed2email supports importing and exporting feed subscriptions as [OPML][]. This
makes it easy to migrate to and away from feed2email anytime you want.

Export feed subscriptions to `feeds.xml`:

~~~
$ # same as "f2e e feeds.xml"
$ feed2email export feeds.xml
This may take a while. Please wait...
Exported 3 feed subscriptions to feeds.xml
~~~

Import feed subscriptions from `feeds.xml`:

~~~
$ # same as "f2e i feeds.xml"
$ feed2email import feeds.xml
Importing...
Feed already exists:   2 https://github.com/agorf.atom
Feed already exists:   3 http://www.rubyinside.com/feed/
Feed already exists:   4 http://thechangelog.com/feed/
~~~

Nothing was imported since all feeds already exist. Let's remove them first and
then try again:

~~~
$ f2e r 2
Remove feed:   2 https://github.com/agorf.atom
Are you sure? [y/n] y
Removed
$ f2e r 3
Remove feed:   3 http://www.rubyinside.com/feed/
Are you sure? [y/n] y
Removed
$ f2e r 4
Remove feed:   4 http://thechangelog.com/feed/
Are you sure? [y/n] y
Removed
$ f2e l
No feeds
$ feed2email import feeds.xml
Importing...
Imported feed:   1 https://github.com/agorf.atom
Imported feed:   2 http://www.rubyinside.com/feed/
Imported feed:   3 http://thechangelog.com/feed/
Imported 3 feed subscriptions from feeds.xml
~~~

Passing the `--remove` option to `import` will remove any feeds not contained in
the imported list, essentially synchronizing the feed subscriptions with it:

~~~
$ # subscribe to a feed that is not in feeds.xml
$ f2e a https://github.com/agorf/feed2email/commits.atom
Added feed:   4 https://github.com/agorf/feed2email/commits.atom
$ f2e l
  1 https://github.com/agorf.atom
  2 http://www.rubyinside.com/feed/
  3 http://thechangelog.com/feed/
  4 https://github.com/agorf/feed2email/commits.atom

Subscribed to 4 feeds
$ f2e import --remove feeds.xml
Importing...
Feed already exists:   1 https://github.com/agorf.atom
Feed already exists:   2 http://www.rubyinside.com/feed/
Feed already exists:   3 http://thechangelog.com/feed/
Removed feed:   4 https://github.com/agorf/feed2email/commits.atom
~~~

### Running

~~~
$ # same as "f2e p"
$ feed2email process
~~~

When run, feed2email will go through your feed list, fetch each feed (if
necessary) and send an email for each new entry. Output is logged to the
standard output, unless configured otherwise.

### Getting help

Issue `feed2email help` (`f2e h`) or just `feed2email` (`f2e`) at any point to
get helpful text on how to use feed2email.

## Contributing

Using feed2email and want to help? [Let me know](https://agorf.gr/) how you use
it and if you have any ideas on how to improve it.

## License

Licensed under the MIT license (see [LICENSE.txt][license]).

[license]: https://github.com/agorf/feed2email/blob/master/LICENSE.txt

## Author

Angelos Orfanakos, <https://agorf.gr/>
