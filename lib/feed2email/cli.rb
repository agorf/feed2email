require 'thor'
require 'feed2email'
require 'feed2email/feed_autodiscoverer'

module Feed2Email
  class Cli < Thor
    desc 'add URL', 'subscribe to feed at URL'
    def add(uri)
      uri = perform_feed_autodiscovery(uri)

      begin
        feed_list << uri
      rescue FeedList::DuplicateFeedError => e
        $stderr.puts e.message
        exit 2
      end

      if feed_list.sync
        puts "Added feed #{uri} at index #{feed_list.size - 1}"
      else
        $stderr.puts 'Failed to add feed'
        exit 3
      end
    end

    desc 'remove FEED', 'unsubscribe from feed at index FEED'
    def remove(index)
      begin
        feed_list.delete_at(index.to_i)
      rescue FeedList::MissingFeedError => e
        $stderr.puts e.message
        exit 4
      end

      if feed_list.sync
        puts "Removed feed at index #{index}"

        if feed_list.size != index.to_i # feed was not the last
          puts
          puts 'Warning: Feed list indices have changed!'
        end
      else
        $stderr.puts "Failed to remove feed at index #{index}"
        exit 5
      end
    end

    desc 'toggle FEED', 'enable/disable feed at index FEED'
    def toggle(index)
      begin
        feed_list.toggle(index.to_i)
      rescue FeedList::MissingFeedError => e
        $stderr.puts e.message
        exit 6
      end

      enabled = feed_list[index.to_i][:enabled]

      if feed_list.sync
        puts "#{enabled ? 'En' : 'Dis'}abled feed at index #{index}"
      else
        $stderr.puts(
          "Failed to #{enabled ? 'en' : 'dis'}able feed at index #{index}"
        )
        exit 7
      end
    end

    desc 'list', 'list feed subscriptions'
    def list
      puts feed_list
    end

    desc 'process', 'process feed subscriptions'
    def process
      feed_list.process
    end

    desc 'version', 'show feed2email version'
    def version
      require 'feed2email/version'
      puts "feed2email #{Feed2Email::VERSION}"
    end

    no_commands do
      def feed_list
        Feed2Email.feed_list # delegate
      end

      def perform_feed_autodiscovery(uri)
        discovered_feeds = FeedAutodiscoverer.new(uri).feeds

        return uri unless discovered_feeds.any?

        return discovered_feeds.first[:uri] if discovered_feeds.size == 1

        justify = discovered_feeds.size.to_s.size

        discovered_feeds.each_with_index do |feed, i|
          puts '%{index}: %{uri} (%{content_type})' % {
            index:        i.to_s.rjust(justify),
            uri:          feed[:uri],
            content_type: feed[:content_type]
          }
        end

        begin
          response = ask('Please enter a feed to subscribe to:')

          unless (0...discovered_feeds.size).map(&:to_s).include?(response)
            raise Interrupt
          end
        rescue Interrupt # ^C
          puts "\nInvalid response. Aborting..."
          exit
        end

        discovered_feeds[response.to_i][:uri]
      end
    end
  end
end
