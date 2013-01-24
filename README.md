# feed2email

RSS/Atom feed updates in your email

## Why

I don't like having a separate application for feeds when I'm already checking my email. I also never read a thing when feeds are kept in a separate place.

The script was written primarily as a replacement of the [rss2email][] program which is rather big, slow, bloated and hard to use.

[rss2email]: http://www.allthingsrss.com/rss2email/

## Installation

Install as a [gem][] from [RubyGems][]:

~~~ sh
$ gem install feed2email
~~~

You also need to have [Sendmail][] working in your system to send mail. I use [msmtp][] which is a nice alternative with a compatible Sendmail interface.

[gem]: http://rubygems.org/gems/feed2email
[RubyGems]: http://rubygems.org/
[Sendmail]: http://en.wikipedia.org/wiki/Sendmail
[msmtp]: http://msmtp.sourceforge.net/

## Use

Create `~/.feed2email/feeds.yml` and add the address of each feed you want to subscribe to, prefixed with a dash and a space.

When run for the first time, the script enters "dry run" mode and exits almost immediately. During dry run mode:

* No feeds are fetched and, thus, no email is sent (existing feed entries are considered already seen)
* `~/.feed2email/cache.yml` is created containing the timestamp of when each feed was last fetched

If you want to receive existing entries from a specific feed, you can alter the timestamp for that feed in `cache.yml` to a value in the past. Next time you run the script, all entries published past that timestamp will be sent with email.

Here's how to run the script:

~~~ sh
$ MAILTO=agorfatagorfdotgr feed2email
~~~

**Note:** Email symbols have been replaced with words to avoid spam.

You can use [cron][] to run the script e.g. once every hour.

[cron]: http://en.wikipedia.org/wiki/Cron

## License

Licensed under the MIT license (see `LICENSE.txt`).

## Author

Aggelos Orfanakos, <http://agorf.gr/>
