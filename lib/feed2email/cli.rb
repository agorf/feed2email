require 'thor'
require 'feed2email'
require 'feed2email/feed_autodiscoverer'
require 'feed2email/redirection_checker'

module Feed2Email
  class Cli < Thor
    desc 'add URL', 'subscribe to feed at URL'
    def add(uri)
      uri = handle_permanent_redirection(uri)
      uri = perform_feed_autodiscovery(uri)

      begin
        feed_list << uri
      rescue FeedList::DuplicateFeedError => e
        abort e.message
      end

      if feed_list.sync
        puts "Added feed #{uri} at index #{feed_list.size - 1}"
      else
        abort 'Failed to add feed'
      end
    end

    desc 'fetch FEED', 'clear fetch cache for feed at index FEED'
    def fetch(index)
      index = check_feed_index(index, in: (0...feed_list.size))
      feed_list.clear_fetch_cache(index)

      if feed_list.sync
        puts "Cleared fetch cache for feed at index #{index}"
      else
        abort "Failed to clear fetch cache for feed at index #{index}"
      end
    end

    desc 'history FEED', 'edit history file of feed at index FEED with $EDITOR'
    def history(index)
      abort '$EDITOR not set' unless ENV['EDITOR']

      index = check_feed_index(index, in: (0...feed_list.size))
      require 'feed2email/feed_history'
      history_path = FeedHistory.new(feed_list[index][:uri]).path
      exec(ENV['EDITOR'], history_path)
    end

    desc 'remove FEED', 'unsubscribe from feed at index FEED'
    def remove(index)
      index = check_feed_index(index, in: (0...feed_list.size))
      deleted = feed_list.delete_at(index)

      if deleted && feed_list.sync
        puts "Removed feed at index #{index}"

        if feed_list.size != index # feed was not the last
          puts 'Warning: Feed list indices have changed!'
        end
      else
        abort "Failed to remove feed at index #{index}"
      end
    end

    desc 'toggle FEED', 'enable/disable feed at index FEED'
    def toggle(index)
      index   = check_feed_index(index, in: (0...feed_list.size))
      toggled = feed_list.toggle(index)
      enabled = feed_list[index][:enabled]

      if toggled && feed_list.sync
        puts "#{enabled ? 'En' : 'Dis'}abled feed at index #{index}"
      else
        abort "Failed to #{enabled ? 'en' : 'dis'}able feed at index #{index}"
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
      def check_feed_index(index, options = {})
        if index.to_i.to_s != index ||
            (options[:in] && !options[:in].include?(index.to_i))
          puts if index.nil? # Ctrl-D
          abort 'Invalid index'
        end

        index.to_i
      end

      def feed_list
        Feed2Email.feed_list # delegate
      end

      def handle_permanent_redirection(uri)
        checker = RedirectionChecker.new(uri)

        if checker.permanently_redirected?
          puts "Got permanently redirected to #{checker.location}"
          checker.location
        else
          uri
        end
      end

      def perform_feed_autodiscovery(uri)
        discoverer = FeedAutodiscoverer.new(uri)

        discovered_feeds = discoverer.feeds.reject {|feed|
          feed_list.include?(feed[:uri])
        }

        if discovered_feeds.empty?
          if discoverer.content_type == 'text/html'
            puts 'Could not find any new feeds'
            exit
          end

          return uri
        end

        justify = discovered_feeds.size.to_s.size

        discovered_feeds.each_with_index do |feed, i|
          puts '%{index}: %{uri} %{title}(%{content_type})' % {
            index:        i.to_s.rjust(justify),
            uri:          feed[:uri],
            title:        feed[:title] ? "\"#{feed[:title]}\" " : '',
            content_type: feed[:content_type]
          }
        end

        begin
          response = ask('Please enter a feed to subscribe to:')
        rescue Interrupt # Ctrl-C
          puts
          exit
        end

        index = check_feed_index(response, in: (0...discovered_feeds.size))
        discovered_feeds[index][:uri]
      end
    end
  end
end
