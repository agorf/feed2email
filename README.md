# feed2email

RSS/Atom feed updates in your email

## Why

I don't like having a separate application for feeds when I'm already checking
my email. I also never read a thing when feeds are kept in a separate place.

feed2email was written primarily as a replacement of [rss2email][] and aims to
be simpler, faster, smaller and easier to use.

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

It is possible to send email via SMTP or an [MTA][]. If `config.yml` contains
options for both, feed2email will use SMTP.

[YAML]: http://en.wikipedia.org/wiki/YAML
[MTA]: http://en.wikipedia.org/wiki/Message_transfer_agent

### Format

Each line in the configuration file contains a key-value pair. Each key-value
pair is separated with a colon: `foo: bar`

### Generic options

* `recipient` (required) is the email address to send email to
* `sender` (required) is the email address to send email from
* `send_delay` (optional) is the number of seconds to wait between each email to
  avoid SMTP server throttling errors (default is `10`; use `0` to disable)
* `log_path` (optional) is the _absolute_ path to the log file (default is
  `true` which logs to standard output; use `false` to disable logging)
* `log_level` (optional) is the logging verbosity level and can be `fatal`
  (least verbose), `error`, `warn`, `info` (default) and `debug` (most verbose)
* `max_entries` (optional) is the maximum number of entries to process per feed
  (default is `20`; use `0` for unlimited)

### SMTP

For this method you need to have access to an SMTP service. [Mailgun][] has a
free plan.

* `smtp_host` (required) is the SMTP service hostname to connect to
* `smtp_port` (required) is the SMTP service port to connect to
* `smtp_user` (required) is the username of your email account
* `smtp_pass` (required) is the password of your email account (see the warning
   below)
* `smtp_tls` (optional) controls TLS (default is `true`; can also be `false`)
* `smtp_auth` (optional) controls the authentication method (default is `login`;
   can also be `plain` or `cram_md5`)

**Warning:** Unless it has correct restricted permissions, anyone with access in
your system will be able to read `config.yml` and your password. To prevent
this, feed2email will not run and complain if it detects the wrong permissions.
You can set the correct permissions with `chmod 600 ~/.feed2email/config.yml`.

[Mailgun]: http://www.mailgun.com/

### MTA

For this method you need to have an [MTA][] with a [Sendmail][]-compatible
interface setup and working in your system like [msmtp][] or [Postfix][].

* `sendmail_path` (optional) is the path to the Sendmail binary (default is
  `/usr/sbin/sendmail`)

[Sendmail]: http://en.wikipedia.org/wiki/Sendmail
[msmtp]: http://msmtp.sourceforge.net/
[Postfix]: http://en.wikipedia.org/wiki/Postfix_(software)

## Use

Create `~/.feed2email/feeds.yml` and add the address of each feed you want to
subscribe to, prefixed with a dash and a space:

~~~ yaml
- https://github.com/agorf/feed2email/commits.atom
~~~

To disable a feed temporarily, comment it:

~~~ yaml
#- https://github.com/agorf/feed2email/commits.atom
~~~

You are now ready to run the program:

~~~ sh
$ feed2email
~~~

When run for the first time, feed2email enters "dry run" mode and exits almost
immediately. During dry run mode:

* No feeds are fetched and, thus, no email is sent (existing feed entries are
  considered already seen)
* `~/.feed2email/history.yml` is created containing processed (seen) entries per
  feed

If you want to receive existing entries from a specific feed, you can manually
delete them from `history.yml`. Next time feed2email runs, they will be
processed (sent as email).

You can use [cron][] to run feed2email automatically e.g. once every hour.

[cron]: http://en.wikipedia.org/wiki/Cron

## License

Licensed under the MIT license (see `LICENSE.txt`).

## Author

Aggelos Orfanakos, <http://agorf.gr/>
