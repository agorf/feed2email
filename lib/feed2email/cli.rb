require 'thor'
require 'feed2email'

module Feed2Email
  class Cli < Thor
    desc 'add URL', 'subscribe to feed at URL'
    def add(uri)
      feed_list << uri
      feed_list.sync
    end

    desc 'remove FEED', 'unsubscribe from feed at index FEED'
    def remove(index)
      feed_list.delete_at(index.to_i)
      feed_list.sync

      if feed_list.size != index.to_i # feed was not the last
        puts 'Warning: Feed list indices have changed!'
      end
    end

    desc 'list', 'list feed subscriptions'
    def list
      puts feed_list unless feed_list.empty?
    end

    desc 'toggle FEED', 'enable/disable feed at index FEED'
    def toggle(index)
      feed_list.toggle(index.to_i)
      feed_list.sync
    end

    desc 'process', 'process feed subscriptions'
    def process
      feed_list.process
    end

    private

    def feed_list
      Feed2Email.feed_list # delegate
    end
  end
end
