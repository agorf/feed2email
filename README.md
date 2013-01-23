# feed2email

RSS/Atom feed updates in your email

## Why

I don't like having a separate application for feeds when I'm already checking
my email. I also never read a thing when feeds are kept in a separate place.

The script was written primarily as a replacement of the [rss2email][] program
which is rather big, slow, bloated and hard to use.

[rss2email]: http://www.allthingsrss.com/rss2email/

## Installation

Using git and [Bundler][]:

~~~ sh
$ git clone git://github.com/agorf/feed2email.git
$ cd feed2email/
$ bundle install
~~~

You also need to have [Sendmail][] working in your system to send mail. I use
[msmtp][] which is a nice alternative with a compatible Sendmail interface.

[Bundler]: http://gembundler.com/
[Sendmail]: http://en.wikipedia.org/wiki/Sendmail
[msmtp]: http://msmtp.sourceforge.net/

## Use

Copy `feeds.yml.sample` to `feeds.yml` and add the address of each feed you want
to subscribe to, prefixed with a dash and a space.

When run for the first time, the script enters "dry run" mode and exits almost
immediately. During dry run mode:

* No feeds are fetched and, thus, no email is sent (existing feed entries are
  considered already seen)
* `cache.yml` is created containing the timestamp of when each feed was last
  fetched

If you want to receive existing entries from a specific feed, you can alter the
timestamp for that feed in `cache.yml` to a value in the past. Next time you run
the script, all entries published past that timestamp will be sent with email.

To run the script manually with [Bundler][]:

~~~ sh
$ MAILTO=agorfatagorfdotgr bundle exec ruby feed2email.rb
~~~

**Note:** I've replaced email symbols with words to avoid spam.

You can place the following line in your crontab to have it run once every hour:

    0 * * * * cd ~/src/feed2email/ && MAILTO=agorfatagorfdotgr ~/.rbenv/versions/1.9.3-p327/bin/bundle exec ruby feed2email.rb

**Note:** You need to have [rbenv][] and [Bundler][] installed for the above to
work. Make sure you adjust (1) the path to the script source, (2) your email,
(3) the path to the Ruby binary!

[rbenv]: https://github.com/sstephenson/rbenv

## License

Licensed under the MIT license (see `LICENSE`).

## Author

Aggelos Orfanakos, <http://agorf.gr/>
