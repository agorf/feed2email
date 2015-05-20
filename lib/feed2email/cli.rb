require 'thor'
require 'feed2email'
require 'feed2email/feed'
require 'feed2email/feed_autodiscoverer'
require 'feed2email/opml_exporter'
require 'feed2email/opml_importer'
require 'feed2email/version'

module Feed2Email
  class Cli < Thor
    desc 'add URL', 'Subscribe to feed at URL'
    def add(uri)
      uri = autodiscover_feeds(uri)

      if feed = Feed[uri: uri]
        abort "Feed already exists: #{feed}"
      end

      feed = Feed.new(uri: uri)

      if feed.save(raise_on_failure: false)
        puts "Added feed: #{feed}"
      else
        abort 'Failed to add feed'
      end
    end

    desc 'backend', 'Open an SQLite console to the database'
    def backend
      exec('sqlite3', Feed2Email.database_path)
    end

    desc 'config', 'Open configuration file with $EDITOR'
    def config
      if ENV['EDITOR']
        exec(ENV['EDITOR'], Feed2Email.config_path)
      else
        abort 'EDITOR environmental variable not set'
      end
    end

    desc 'export PATH', 'Export feed subscriptions as OPML to PATH'
    def export(path)
      if Feed.empty?
        abort 'No feeds to export'
      end

      unless File.exist?(path)
        puts 'This may take a while. Please wait...'

        if n = OPMLExporter.export(path)
          puts "Exported #{'feed subscription'.pluralize(n)} to #{path}"
        else
          abort 'Failed to export feed subscriptions'
        end
      else
        abort 'File already exists'
      end
    end

    desc 'import PATH', 'Import feed subscriptions as OPML from PATH'
    def import(path)
      if File.exist?(path)
        puts 'Importing...'

        if n = OPMLImporter.import(path)
          if n > 0
            puts "Imported #{'feed subscription'.pluralize(n)} from #{path}"
          end
        else
          abort 'Failed to import feed subscriptions'
        end
      else
        abort 'File does not exist'
      end
    end

    desc 'list', 'List feed subscriptions'
    def list
      if Feed.any?
        puts Feed.by_smallest_id.to_a
        puts "\nSubscribed to #{'feed'.pluralize(Feed.count)}"
      else
        puts 'No feeds'
      end
    end

    desc 'process', 'Process feed subscriptions'
    def process
      Feed.enabled.by_smallest_id.each(&:process)
    end

    desc 'remove ID', 'Unsubscribe from feed with id ID'
    def remove(id)
      feed = Feed[id]

      if feed
        puts "Remove feed: #{feed}"

        if ask('Are you sure? (yes/no)') == 'yes'
          if feed.delete
            puts 'Removed'
          else
            abort 'Failed to remove feed'
          end
        else
          puts 'Not removed'
        end
      else
        abort "Feed not found. Is #{id} a valid id?"
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
      puts "feed2email #{Feed2Email::VERSION}"
    end

    no_commands do
      def autodiscover_feeds(uri)
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

        unless response.numeric? &&
            (0...discovered_feeds.size).include?(response.to_i)
          abort 'Invalid index'
        end

        feed = discovered_feeds[response.to_i]

        abort 'Invalid index' unless feed && feed[:uri]

        feed[:uri]
      end
    end
  end
end
