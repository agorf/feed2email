# feed2email [![Gem Version](https://badge.fury.io/rb/feed2email.svg)](http://badge.fury.io/rb/feed2email)

feed2email is a [headless][] RSS/Atom feed aggregator that sends feed entries
via email. It was initially written as a replacement of [rss2email][] and aims
to be simple, fast and easy to use.

[headless]: http://en.wikipedia.org/wiki/Headless_software
[rss2email]: http://www.allthingsrss.com/rss2email/

## Features

* Easy command-line feed management (add, remove, enable/disable)
* Feed fetching caching
* Feed autodiscovery
* Support for sending email with SMTP or a local MTA (e.g. sendmail)
* _text/html_ and _text/plain_ (Markdown) multipart emails
* Support for feed permanent redirections
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

### Generic options

* `recipient` (required) is the email address to send email to
* `sender` (required) is the email address to send email from (can be any)
* `send_delay` (optional) is the number of seconds to wait between each email to
  avoid SMTP server throttling errors (default is `10`; use `0` to disable)
* `max_entries` (optional) is the maximum number of entries to process per feed
  (default is `20`; use `0` for unlimited)

#### Logging options

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

It is possible to send email via SMTP or an [MTA][] (default). If `config.yml`
contains options for both, feed2email will use SMTP.

[MTA]: http://en.wikipedia.org/wiki/Message_transfer_agent

### SMTP options

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
To set the correct permissions, issue `chmod 600 ~/.feed2email/config.yml`

[Mailgun]: http://www.mailgun.com/

### MTA options

For this method you need to have an [MTA][] with a [Sendmail][]-compatible
interface set up and working in your system like [msmtp][] or [Postfix][].

* `sendmail_path` (optional) is the path to the Sendmail binary (default is
  `/usr/sbin/sendmail`)

[Sendmail]: http://en.wikipedia.org/wiki/Sendmail
[msmtp]: http://msmtp.sourceforge.net/
[Postfix]: http://en.wikipedia.org/wiki/Postfix_(software)

## Use

### Managing feeds

First, add some feeds:

~~~ sh
$ feed2email add https://github.com/agorf.atom
Added feed https://github.com/agorf.atom at index 0
$ feed2email add https://github.com/agorf/feed2email/commits.atom
Added feed https://github.com/agorf/feed2email/commits.atom at index 1
~~~

**Tip:** You only have to type a feed2email command until it is unambiguous e.g.
instead of `feed2email list`, you can simply issue `feed2email l` as long as
there is no other command beginning with an `l`.

It is also possible to pass a website URL and let feed2email autodiscover any
feeds:

~~~ sh
$ feed2email add http://www.rubyinside.com/
Added feed http://www.rubyinside.com/feed/ at index 2
$ feed2email add http://thechangelog.com/137/
0: http://thechangelog.com/137/feed/ (application/rss+xml)
1: http://thechangelog.com/feed/ (application/rss+xml)
Please enter a feed to subscribe to: 1
Added feed http://thechangelog.com/feed/ at index 3
~~~

Note that in the first example, feed2email autodiscovers and adds the only feed
listed at [Ruby Inside](http://www.rubyinside.com/). In the second example, the
[The Changelog](http://thechangelog.com/) podcast episode page has two feeds
listed, so feed2email prompts you to choose one and subsequently adds it.

The feed list so far:

~~~ sh
$ feed2email list
0: https://github.com/agorf.atom
1: https://github.com/agorf/feed2email/commits.atom
2: http://www.rubyinside.com/feed/
3: http://thechangelog.com/feed/
~~~

To disable a feed so that it is not processed with `feed2email process`, issue:

~~~ sh
$ feed2email toggle 1
Disabled feed at index 1
$ feed2email list
0: https://github.com/agorf.atom
1: DISABLED https://github.com/agorf/feed2email/commits.atom
2: http://www.rubyinside.com/feed/
3: http://thechangelog.com/feed/
~~~

It is also possible to remove it from the list:

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

### Processing feeds

To have feed2email process your feed list and send email if necessary, issue:

~~~ sh
$ feed2email process
~~~

When a new feed is detected (which is the case when feed2email runs for the
first time on your feed list), all of its entries are skipped and no email is
sent. This is so that you don't get spammed when you add a feed for the first
time.

If you want to receive a specific entry from a newly added feed, remove it (i.e.
with your text editor) from the feed's history file
`~/.feed2email/history-<digest>.yml`, where `<digest>` is the MD5 hex digest of
the feed URL. Then edit `~/.feed2email/feeds.yml` and remove its `last_modified`
and `etag` keys to force the feed to be fetched (this busts caching).

Next time you issue `feed2email process`, the entry will be treated as new and
will be processed (sent as email).

### Getting help

Issue `feed2email` or `feed2email help` at any point to get a helpful text on
how to use feed2email.

### Automating

You can use [cron][] to run feed2email automatically e.g. once every hour.

[cron]: http://en.wikipedia.org/wiki/Cron

## Contributing

Using feed2email and want to help? Just [contact me](http://agorf.gr/) and
describe how you use it and if you have any ideas on how it can be improved.

## License

Licensed under the MIT license (see `LICENSE.txt`).

## Author

Aggelos Orfanakos, <http://agorf.gr/>
