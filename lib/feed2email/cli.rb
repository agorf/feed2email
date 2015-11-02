require 'thor'
require 'feed2email'
require 'feed2email/feed'
require 'feed2email/feed_autodiscoverer'
require 'feed2email/opml_reader'
require 'feed2email/opml_writer'
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
      abort "File already exists" if File.exist?(path)

      abort "No feeds to export" if Feed.empty?

      puts "Exporting... (this may take a while)"

      exported = open(path, "w") do |f|
        uris = Feed.oldest_first.select_map(:uri)

        if OPMLWriter.new(uris).write(f) > 0
          uris.size
        end
      end

      if exported > 0
        puts "Exported #{'feed subscription'.pluralize(exported)} to #{path}"
      else
        puts "No feed subscriptions exported"
      end
    end

    desc 'import PATH', 'Import feed subscriptions as OPML from PATH'
    option :remove, type: :boolean, default: false,
      desc: "Unsubscribe from feeds not in imported list"
    def import(path)
      abort "File does not exist" unless File.exist?(path)

      puts "Importing..."

      feeds = open(path) {|f| OPMLReader.new(f).feeds }

      imported = 0

      feeds.each do |uri|
        if feed = Feed[uri: uri]
          warn "Feed already exists: #{feed}"
        else
          feed = Feed.new(uri: uri)

          if feed.save(raise_on_failure: false)
            puts "Imported feed: #{feed}"
            imported += 1
          else
            warn "Failed to import feed: #{feed}"
          end
        end
      end

      if options[:remove]
        Feed.exclude(uri: feeds).each do |feed|
          if feed.delete
            puts "Removed feed: #{feed}"
          else
            warn "Failed to remove feed: #{feed}"
          end
        end
      end

      if imported > 0
        puts "Imported #{'feed subscription'.pluralize(imported)} from #{path}"
      else
        puts "No feed subscriptions imported"
      end
    end

    desc 'list', 'List feed subscriptions'
    def list
      if Feed.any?
        puts Feed.oldest_first.to_a
        print "\nSubscribed to #{'feed'.pluralize(Feed.count)}"

        if Feed.where(enabled: false).count > 0
          print " (#{Feed.enabled.count} enabled)"
        end

        puts
      else
        puts 'No feeds'
      end
    end

    desc 'process', 'Process feed subscriptions'
    def process
      if config_data["send_method"] == "smtp"
        with_smtp_connection do |smtp|
          Feed2Email.smtp_connection = smtp
          Feed.enabled.oldest_first.each(&:process)
          Feed2Email.smtp_connection = nil
        end
      else
        Feed.enabled.oldest_first.each(&:process)
      end
    end

    desc 'remove ID', 'Unsubscribe from feed with id ID'
    def remove(id)
      unless feed = Feed[id]
        abort "Feed not found. Is #{id} a valid id?"
      end

      puts "Remove feed: #{feed}"

      if ask('Are you sure?', limited_to: %w{y n}) == 'y'
        if feed.delete
          puts 'Removed'
        else
          abort 'Failed to remove feed'
        end
      else
        puts 'Not removed'
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
          if discoverer.discoverable?
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
          response = ask(
            'Please enter a feed to subscribe to (or Ctrl-C to abort):',
            limited_to: (0...discovered_feeds.size).to_a.map(&:to_s)
          )
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

      def config_data
        Feed2Email.config
      end

      # TODO make lazy with a wrapper
      def with_smtp_connection(&block)
        smtp = Net::SMTP.new(config_data["smtp_host"], config_data["smtp_port"])
        smtp.enable_starttls if config_data["smtp_starttls"]
        smtp.start("localhost", config_data["smtp_user"], config_data["smtp_pass"],
                   config_data["smtp_auth"].to_sym, &block)
      end
    end
  end
end
