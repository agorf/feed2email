require 'thor'

module Feed2Email
  class Cli < Thor
    desc 'add URL', 'Subscribe to feed at URL'
    def add(uri)
      require 'feed2email/feed'
      require 'feed2email/feed_autodiscoverer'

      uri = autodiscover_feeds(uri)

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

    desc 'backend', 'Open an SQLite console to the database'
    def backend
      require 'feed2email'
      exec('sqlite3', Feed2Email.database_path)
    end

    desc 'config', 'Open configuration file with $EDITOR'
    def config
      if ENV['EDITOR']
        require 'feed2email'
        exec(ENV['EDITOR'], Feed2Email.config_path)
      else
        abort 'EDITOR not set'
      end
    end

    desc 'export PATH', 'Export feed subscriptions as OPML to PATH'
    def export(path)
      unless File.exist?(path)
        require 'feed2email/opml_exporter'

        puts 'This may take a bit. Please wait...'

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
        require 'feed2email/opml_importer'

        puts 'Importing...'

        if n = OPMLImporter.import(path)
          puts "Imported #{'feed subscription'.pluralize(n)} from #{path}"
        else
          abort 'Failed to import feed subscriptions'
        end
      else
        abort 'File does not exist'
      end
    end

    desc 'list', 'List feed subscriptions'
    def list
      require 'feed2email/feed'

      if Feed.empty?
        puts 'No feeds'
      else
        puts Feed.by_smallest_id.to_a
      end
    end

    desc 'process', 'Process feed subscriptions'
    def process
      require 'feed2email'
      require 'feed2email/feed'

      begin
        Feed.enabled.by_smallest_id.each(&:process)
      ensure
        Feed2Email.smtp_connection.finalize
      end
    end

    desc 'remove ID', 'Unsubscribe from feed with id ID'
    def remove(id)
      require 'feed2email/feed'

      feed = Feed[id]

      if feed && feed.delete
        puts "Removed feed: #{feed}"
      else
        abort "Failed to remove feed. Is #{id} a valid id?"
      end
    end

    desc 'toggle ID', 'Enable/disable feed with id ID'
    def toggle(id)
      require 'feed2email/feed'

      feed = Feed[id]

      if feed && feed.toggle
        puts "Toggled feed: #{feed}"
      else
        abort "Failed to toggle feed. Is #{id} a valid id?"
      end
    end

    desc 'uncache ID', 'Clear fetch cache for feed with id ID'
    def uncache(id)
      require 'feed2email/feed'

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
