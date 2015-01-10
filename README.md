# feed2email [![Gem Version](https://badge.fury.io/rb/feed2email.svg)](http://badge.fury.io/rb/feed2email)

RSS/Atom feed updates in your email

## Why

I don't like having a separate application for feeds when I'm already checking
my email. I also never read a thing when feeds are kept in a separate place.

feed2email is a [headless][] RSS/Atom feed aggregator that sends feed entries
via email. It was written primarily as a replacement of [rss2email][] and aims
to be simple, fast and easy to use.

[headless]: http://en.wikipedia.org/wiki/Headless_software
[rss2email]: http://www.allthingsrss.com/rss2email/

## Installation

Install as a [gem][] from [RubyGems][]:

~~~ sh
$ gem install feed2email
~~~

[gem]: http://rubygems.org/gems/feed2email
[RubyGems]: http://rubygems.org/

## Configuration

Through a [YAML][] file at `~/.feed2email/config.yml`.

[YAML]: http://en.wikipedia.org/wiki/YAML

Each line in the configuration file contains a key-value pair. Each key-value
pair is separated with a colon: `foo: bar`

### Generic options

* `recipient` (required) is the email address to send email to
* `sender` (required) is the email address to send email from (can be any)
* `send_delay` (optional) is the number of seconds to wait between each email to
  avoid SMTP server throttling errors (default is `10`; use `0` to disable)
* `log_path` (optional) is the _absolute_ path to the log file (default is
  `true` which logs to standard output; use `false` to disable logging)
* `log_level` (optional) is the logging verbosity level and can be `fatal`
  (least verbose), `error`, `warn`, `info` (default) and `debug` (most verbose)
* `log_shift_age` (optional) is the number of _old_ log files to keep or the
  frequency of rotation (`daily`, `weekly`, `monthly`; default is `0` so only
  the current log file is kept)
* `log_shift_size` (optional) is the maximum log file size in bytes and it only
  applies when `log_shift_age` is a number greater than zero (default is
  `1048576` for 1 megabyte)
* `max_entries` (optional) is the maximum number of entries to process per feed
  (default is `20`; use `0` for unlimited)

It is possible to send email via SMTP or an [MTA][] (default). If `config.yml`
contains options for both, feed2email will use SMTP.

[MTA]: http://en.wikipedia.org/wiki/Message_transfer_agent

### SMTP

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

### MTA

For this method you need to have an [MTA][] with a [Sendmail][]-compatible
interface set up and working in your system like [msmtp][] or [Postfix][].

* `sendmail_path` (optional) is the path to the Sendmail binary (default is
  `/usr/sbin/sendmail`)

[Sendmail]: http://en.wikipedia.org/wiki/Sendmail
[msmtp]: http://msmtp.sourceforge.net/
[Postfix]: http://en.wikipedia.org/wiki/Postfix_(software)

## Use

### Managing feeds

Create or edit `~/.feed2email/feeds.yml` and add the URL of the feed you want to
subscribe to, prefixed with a dash and a space:

~~~ yaml
- https://github.com/agorf/feed2email/commits.atom
~~~

To disable a feed, comment its line by prefixing it with a hash symbol:

~~~ yaml
#- https://github.com/agorf/feed2email/commits.atom
~~~

### Running for the first time

When feed2email runs for the first time or after adding a new feed:

* All feed entries are skipped (no email sent)
* `~/.feed2email/history-<digest>.yml` is created for each feed containing these
  (old) entries, where `<digest>` is the MD5 hex digest of the feed URL

**Warning:** Versions prior to 0.6.0 used a single history file for all feeds.
Before using version 0.6.0 for the first time, please make sure you run the
provided migration script: `feed2email-migrate-history` If you don't, feed2email
will think it's run for the first time and will treat all entries as old (thus
no email will be sent and you may miss some entries).

### Receiving specific entries from a feed

1. Add the feed URL to `~/.feed2email/feeds.yml`
1. Run feed2email once so that the feed's history file is generated
1. Remove the entries you want to receive from the feed's history (i.e. with
   your text editor)
1. Remove the feed's meta file (`meta-<digest>.yml`, where `<digest>` is the MD5
   hex digest of the feed URL) to bust feed fetching caching

Next time feed2email runs, these entries will be treated as new and will be
processed (sent as email).

### Permanent redirections

Before processing each feed, feed2email issues a [HEAD request][] to check
whether it has been permanently moved by looking for a _301 Moved Permanently_
HTTP status and its respective _Location_ header. In such case, feed2email
updates `~/.feed2email/feeds.yml` with the new location and all feed entries are
skipped (no email sent). If you do want to have some of them sent as email, see
[Receiving specific entries from a feed](#receiving-specific-entries-from-a-feed).

[HEAD request]: http://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol#Request_methods

### Feed caching

feed2email caches fetched feeds with the _Last-Modified_ and _Etag_ HTTP
headers. If you want to force a feed to be fetched, remove the feed's meta file
(`~/.feed2email/meta-<digest>.yml`, where `<digest>` is the MD5 hex digest of
the feed URL). Next time feed2email runs, the feed will be fetched.

### Automating

You can use [cron][] to run feed2email automatically e.g. once every hour.

[cron]: http://en.wikipedia.org/wiki/Cron

## License

Licensed under the MIT license (see `LICENSE.txt`).

## Author

Aggelos Orfanakos, <http://agorf.gr/>
