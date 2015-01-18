require 'thor'
require 'feed2email'
require 'feed2email/feed'

module Feed2Email
  class Cli < Thor
    desc 'add URL', 'Subscribe to feed at URL'
    def add(uri)
      require 'feed2email/feed_autodiscoverer'
      require 'feed2email/redirection_checker'

      uri = handle_permanent_redirection(uri)
      uri = perform_feed_autodiscovery(uri)

      begin
        feed = Feed.create(uri: uri)
        puts "Added feed: #{feed}"
      rescue Sequel::UniqueConstraintViolation => e
        if e.message =~ /unique .* feeds.uri/i
          feed = Feed[uri: uri]
          abort "Feed already exists: #{feed}"
        else
          raise
        end
      end
    end

    desc 'list', 'List feed subscriptions'
    def list
      if Feed.empty?
        puts 'No feeds'
      else
        puts Feed.by_smallest_id.to_a
      end
    end

    desc 'process', 'Process feed subscriptions'
    def process
      begin
        Feed.enabled.by_smallest_id.each(&:process)
      ensure
        Feed2Email.smtp_connection.finalize
      end
    end

    desc 'remove ID', 'Unsubscribe from feed with id ID'
    def remove(id)
      feed = Feed[id]

      if feed && feed.delete
        puts "Removed feed: #{feed}"
      else
        abort "Failed to remove feed. Is #{id} a valid id?"
      end
    end

    desc 'toggle ID', 'Enable/disable feed with id ID'
    def toggle(id)
      feed = Feed[id]

      if feed && feed.toggle
        puts "Toggled feed: #{feed}"
      else
        abort "Failed to toggle feed. Is #{id} a valid id?"
      end
    end

    desc 'uncache ID', 'Clear fetch cache for feed with id ID'
    def uncache(id)
      feed = Feed[id]

      if feed && feed.uncache
        puts "Uncached feed: #{feed}"
      else
        abort "Failed to uncache feed. Is #{id} a valid id?"
      end
    end

    desc 'version', 'Show feed2email version'
    def version
      require 'feed2email/version'
      puts "feed2email #{Feed2Email::VERSION}"
    end

    no_commands do
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

        # Exclude already subscribed feeds from results
        subscribed_feed_uris = Feed.select_map(:uri)
        discovered_feeds = discoverer.feeds.reject {|feed|
          subscribed_feed_uris.include?(feed[:uri])
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

        abort 'Invalid index' unless response.to_i.to_s == response

        feed = discovered_feeds[response.to_i]

        abort 'Invalid index' unless feed && feed[:uri]

        feed[:uri]
      end
    end
  end
end
