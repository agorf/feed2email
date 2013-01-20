# coding: utf-8
require 'feedzirra'
require 'mail'

SENDMAIL_BIN = ENV['SENDMAIL_BIN'] || '/usr/sbin/sendmail'
RECIPIENT = ENV['RECIPIENT']

feed_uris = YAML.load(open('feeds.yml')) rescue []
fetch_times = YAML.load(open('cache.yml')) rescue {}

feed_uris.each do |feed_uri|
  fetched_at = Time.now
  feed = Feedzirra::Feed.fetch_and_parse(feed_uri)

  if feed.respond_to?(:entries)
    if fetch_times[feed_uri]
      feed.entries.each do |entry|
        if entry.published > fetch_times[feed_uri]
          mail = Mail.new do
            from entry.author if entry.author
            to RECIPIENT
            subject "[#{feed.title}] #{entry.title}"
            html_part do
              content_type 'text/html; charset=UTF-8'
              body entry.summary
            end
          end

          open("|#{SENDMAIL_BIN} #{mail.to.join(' ')}", 'w') do |f|
            f.write(mail)
          end
        end
      end
    end

    fetch_times[feed_uri] = fetched_at
  end
end

open('cache.yml', 'w') {|f| f.write(fetch_times.to_yaml) }
