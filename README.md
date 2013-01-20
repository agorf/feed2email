# rss2email

Receive RSS/Atom feed updates in your email.

## Why

I don't like having a separate application for feeds when I'm checking my email
anyway. I also never read anything when feeds are kept in a separate place.

The script was written primarily as a replacement of the [rss2email][] program
which is big, bloated, buggy and hard to configure.

[rss2email]: http://www.allthingsrss.com/rss2email/

## Installation

It's easy with [Bundler][]:

    $ git clone git://github.com/agorf/rss2email.git
    $ cd rss2email/
    $ bundle install

You also need to have [Sendmail][] working in your system to send mail. I use
[msmtp][] which is a nice alternative with a compatible Sendmail interface.

[Bundler]: http://gembundler.com/
[Sendmail]: http://en.wikipedia.org/wiki/Sendmail
[msmtp]: http://msmtp.sourceforge.net/

## Use

Copy `feeds.yml.sample` to `feeds.yml` and add the address of each feed you want
to subscribe to, prefixed with a dash and a space.

When run for the first time, the script runs in "dry run" mode which is why it
exits almost immediately. During dry run mode:

* No feeds are fetched and, thus, no email is sent (existing feed entries are
  considered already seen)
* `cache.yml` is created containing the timestamp of when each feed was last
  fetched

If you want to receive existing entries from a specific feed, you can alter the
timestamp for that feed in `cache.yml` to a value in the past. Next time you run
the script, all entries published past that timestamp will be sent with email.

Here's how to run the script manually with [Bundler][]:

    $ MAILTO=agorfatagorfdotgr bundle exec ruby rss2email.rb

**Note:** I've replaced email symbols with words to avoid spam.

You can place the following line in your crontab to have it run once every hour:

    0 * * * * cd ~/src/rss2email/ && MAILTO=agorfatagorfdotgr ~/.rbenv/versions/1.9.3-p327/bin/bundle exec ruby rss2email.rb

**Note:** You need to have [rbenv][] and [Bundler][] installed for the above to
work. Don't forget to adjust (1) the path to the script source, (2) your email,
(3) the path to the Ruby binary!

[rbenv]: https://github.com/sstephenson/rbenv

## License

(The MIT License)

Copyright (c) 2013 Aggelos Orfanakos

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Author

Aggelos Orfanakos, <http://agorf.gr/>
