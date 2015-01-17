# feed2email [![Gem Version](https://badge.fury.io/rb/feed2email.svg)](http://badge.fury.io/rb/feed2email)

feed2email is a [headless][] RSS/Atom feed aggregator that sends feed entries
via email. It was initially written as a replacement of [rss2email][] and aims
to be simple, fast and easy to use.

[headless]: http://en.wikipedia.org/wiki/Headless_software
[rss2email]: http://www.allthingsrss.com/rss2email/

## Features

* Easy command-line feed management (add, remove, enable/disable)
* Feed fetching caching (_Last-Modified_ and _ETag_ HTTP headers)
* Feed autodiscovery
* Email sending with SMTP or a local MTA (e.g. sendmail)
* _text/html_ and _text/plain_ (Markdown) multipart emails
* Permanent redirection support for feed URLs
* Auto-fixing relative feed entry permalinks

## Installation

As a [gem][] from [RubyGems][]:

~~~ sh
$ gem install feed2email
~~~

[gem]: http://rubygems.org/gems/feed2email
[RubyGems]: http://rubygems.org/

## Configuration

Through a [YAML][] file that you create at `~/.feed2email/config.yml`.

[YAML]: http://en.wikipedia.org/wiki/YAML

Each line in the configuration file contains a key-value pair. Each key-value
pair is separated with a colon, e.g.: `foo: bar`

### General options

* `recipient` (required) is the email address to send email to
* `sender` (required) is the email address to send email from (can be any)
* `send_delay` (optional) is the number of seconds to wait between each email to
  avoid SMTP server throttling errors (default is `10`; use `0` to disable)
* `max_entries` (optional) is the maximum number of entries to process per feed
  (default is `20`; use `0` for unlimited)

### Logging options

* `log_path` (optional) is the _absolute_ path to the log file (default is
  `true` which logs to standard output; use `false` to disable logging)
* `log_level` (optional) is the logging verbosity level and can be `fatal`
  (least verbose), `error`, `warn`, `info` (default) and `debug` (most verbose)
* `log_shift_age` (optional) is the number of _old_ log files to keep or the
  frequency of rotation (`daily`, `weekly`, `monthly`; default is `0` so only
  the current log file is kept)
* `log_shift_size` (optional) is the maximum log file size in _megabytes_ and it
  only applies when `log_shift_age` is a number greater than zero (default is
  `1`)

### Email sending options

It is possible to send email via SMTP or an [MTA][] (default). If `config.yml`
contains options for both, feed2email will prefer SMTP.

[MTA]: http://en.wikipedia.org/wiki/Message_transfer_agent

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
To set the correct permissions, issue `chmod 600 ~/.feed2email/config.yml`.

[Mailgun]: http://www.mailgun.com/

#### MTA

For this method you need to have an [MTA][] with a [Sendmail][]-compatible
interface set up and working in your system like [msmtp][] or [Postfix][].

* `sendmail_path` (optional) is the path to the Sendmail binary (default is
  `/usr/sbin/sendmail`)

[Sendmail]: http://en.wikipedia.org/wiki/Sendmail
[msmtp]: http://msmtp.sourceforge.net/
[Postfix]: http://en.wikipedia.org/wiki/Postfix_(software)

## Use

### Managing feeds

Add some feeds:

~~~ sh
$ feed2email add https://github.com/agorf.atom
Added feed https://github.com/agorf.atom at index 0
$ feed2email add https://github.com/agorf/feed2email/commits.atom
Added feed https://github.com/agorf/feed2email/commits.atom at index 1
~~~

**Tip:** You only have to type a feed2email command until it is unambiguous e.g.
instead of `feed2email list`, you can simply issue `feed2email l` as long as
there is no other command beginning with an `l`.

Passing a website URL to the `add` command will have feed2email autodiscover any
feeds:

~~~ sh
$ feed2email add http://www.rubyinside.com/
0: http://www.rubyinside.com/feed/ "Ruby Inside" (application/rss+xml)
Please enter a feed to subscribe to: 0
Added feed http://www.rubyinside.com/feed/ at index 2
$ feed2email add http://thechangelog.com/137/
0: http://thechangelog.com/137/feed/ "The Changelog » #137: Better GitHub Issues with HuBoard and Ryan Rauh Comments Feed" (application/rss+xml)
1: http://thechangelog.com/feed/ "RSS 2.0 Feed" (application/rss+xml)
Please enter a feed to subscribe to: 1
Added feed http://thechangelog.com/feed/ at index 3
$ feed2email add http://thechangelog.com/137/
0: http://thechangelog.com/137/feed/ "The Changelog » #137: Better GitHub Issues with HuBoard and Ryan Rauh Comments Feed" (application/rss+xml)
Please enter a feed to subscribe to: ^C
~~~

Note that on the last command, feed2email autodiscovers the same two feeds as in
the second command, but only lists the one that hasn't been already added.
Autodiscovery is then cancelled by pressing `Ctrl-C`.

The feed list so far:

~~~ sh
$ feed2email list
0: https://github.com/agorf.atom
1: https://github.com/agorf/feed2email/commits.atom
2: http://www.rubyinside.com/feed/
3: http://thechangelog.com/feed/
~~~

A feed can be disabled so that it is not processed when `feed2email process`
runs with the `toggle` command:

~~~ sh
$ feed2email toggle 1
Disabled feed at index 1
$ feed2email list
0: https://github.com/agorf.atom
1: DISABLED https://github.com/agorf/feed2email/commits.atom
2: http://www.rubyinside.com/feed/
3: http://thechangelog.com/feed/
~~~

It can also be removed from the list altogether:

~~~ sh
$ feed2email remove 1
Removed feed at index 1
Warning: Feed list indices have changed!
~~~

It has been removed, but what is that weird warning?

Since the feed that got removed was at index 1, every feed below it got
reindexed. So feed2email warns you that the feed indices have changed: the feed
at index 2 is now at index 1 and the feed at index 3 is now at index 2.

Indeed:

~~~ sh
$ feed2email list
0: https://github.com/agorf.atom
1: http://www.rubyinside.com/feed/
2: http://thechangelog.com/feed/
~~~

**Tip:** feed2email installs `f2e` as a symbolic link to the feed2email binary,
so you can use that to avoid typing the whole name every time, e.g.: `f2e list`
or even `f2e l`.

### Running

~~~ sh
$ feed2email process
~~~

When run, feed2email will go through your feed list, fetch each feed (if
necessary) and send an email for each new entry. Output is logged to the
standard output, unless configured otherwise.

**Warning:** Prior to version 0.8.0 where a command-line interface was
introduced, the way to run feed2email was simply `feed2email`. Now this will
just print helpful text on how to use it.

When a new feed is detected (which is the case when feed2email runs for the
first time on your feed list), all of its entries are skipped and no email is
sent. This is so that you don't get spammed when you add a feed for the first
time.

If you want to receive a specific entry from a newly added feed, edit the feed's
history file with `feed2email history` and remove the entry. Then issue
`feed2email fetch` to clear the feed's fetch cache. Next time
`feed2email process` runs, the entry will be treated as new and will be
processed.

### Getting help

Issue `feed2email` or `feed2email help` at any point to get helpful text on how
to use feed2email.

## Contributing

Using feed2email and want to help? Just [contact me](http://agorf.gr/) and
describe how you use it and if you have any ideas on how it can be improved.

## License

Licensed under the MIT license (see `LICENSE.txt`).

## Author

Aggelos Orfanakos, <http://agorf.gr/>
