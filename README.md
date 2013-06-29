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

It is possible to send mail via SMTP or an [MTA][]. If `config.yml` contains
options for both, feed2email will use SMTP.

[YAML]: http://en.wikipedia.org/wiki/YAML
[MTA]: http://en.wikipedia.org/wiki/Message_transfer_agent

### Format

Each line in the configuration file contains a key-value pair. Each key-value
pair is separated with a colon: `foo: bar`

### Generic options

* `recipient` (required) is the email address to send email to
* `send_delay` (optional) is the number of seconds to wait between each email to
   avoid SMTP server throttling errors (default is `10`; use `0` to turn off)

### SMTP

* `smtp_host` is the SMTP service hostname to connect to
* `smtp_port` is the SMTP service port to connect to
* `smtp_user` is the username of your mail account
* `smtp_pass` is the password of your mail account (see the warning below)
* `smtp_tls` (optional) controls TLS (default is `true`; can also be `false`)
* `smtp_auth` (optional) controls the authentication method (default is `login`;
   can also be `plain` or `cram_md5`)

**Warning:** Unless it has correct restricted permissions, anyone with access in
your system will be able to read `config.yml` and your password. To prevent
this, feed2email will not run and complain if it detects the wrong permissions.
You can set the correct permissions with `chmod 600 ~/.feed2email/config.yml`.

### MTA

For this method you need to have an [MTA][] with a [Sendmail][]-compatible
interface setup and working in your system. I suggest [msmtp][] or [Postfix][].

* `sendmail_path` (optional) is the path to the Sendmail binary (default is
  `/usr/sbin/sendmail`)

[Sendmail]: http://en.wikipedia.org/wiki/Sendmail
[msmtp]: http://msmtp.sourceforge.net/
[Postfix]: http://en.wikipedia.org/wiki/Postfix_(software)

## Use

Create `~/.feed2email/feeds.yml` and add the address of each feed you want to
subscribe to, prefixed with a dash and a space.

Then run it:

~~~ sh
$ feed2email
~~~

When run for the first time, feed2email enters "dry run" mode and exits almost
immediately. During dry run mode:

* No feeds are fetched and, thus, no email is sent (existing feed entries are
  considered already seen)
* `~/.feed2email/state.yml` is created containing the timestamp of when each
  feed was last fetched

If you want to receive existing entries from a specific feed, you can manually
alter the timestamp for that feed in `state.yml` to a value in the past. Next
time you run feed2email, all entries published past that timestamp will be sent
with email.

You can use [cron][] to run feed2email automatically e.g. once every hour.

[cron]: http://en.wikipedia.org/wiki/Cron

## License

Licensed under the MIT license (see `LICENSE.txt`).

## Author

Aggelos Orfanakos, <http://agorf.gr/>
