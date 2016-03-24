require 'thor'
require 'feed2email/core_ext/string_refinements'

module Feed2Email
  class Cli < Thor
    using CoreExt::StringRefinements

    desc 'add URL', 'Subscribe to feed at URL'
    option :send_existing, type: :boolean, default: false,
      desc: 'Send email for existing entries'
    def add(uri)
      require 'feed2email'
      Feed2Email.setup_database
      require 'feed2email/feed'

      begin
        uri = autodiscover_feeds(uri)
      rescue => e
        error e.message
      end

      if feed = Feed[uri: uri]
        error "Feed already exists: #{feed}"
      end

      feed = Feed.new(uri: uri, send_existing: options[:send_existing])

      unless feed.save_without_raising
        error 'Failed to add feed'
      end

      puts "Added feed: #{feed}"
    end

    desc 'backend', 'Open an SQLite console to the database'
    def backend
      require 'feed2email'
      exec('sqlite3', Feed2Email.database_path)
    end

    desc 'config', 'Open configuration file with $EDITOR'
    def config
      if ENV['EDITOR'].nil?
        error 'EDITOR environmental variable not set'
      end

      require 'feed2email'
      Feed2Email.config # create default config if necessary

      exec(ENV['EDITOR'], Feed2Email.config_path)
    end

    desc 'export PATH', 'Export feed subscriptions as OPML to PATH'
    def export(path)
      return if File.exist?(path) && !file_collision(path)

      require 'feed2email'
      Feed2Email.setup_database
      require 'feed2email/feed'

      error 'No feeds to export' if Feed.empty?

      require 'feed2email/opml_writer'

      puts "Exporting... (this may take a while)"

      exported = File.open(path, "w") do |f|
        uris = Feed.oldest_first.select_map(:uri)

        if OPMLWriter.new(uris).write(f) > 0
          uris.size
        end
      end

      if exported && exported > 0
        puts "Exported #{'feed subscription'.pluralize(exported)} to #{path}"
      else
        puts "No feed subscriptions exported"
      end
    end

    desc 'import PATH', 'Import feed subscriptions as OPML from PATH'
    option :remove, type: :boolean, default: false,
      desc: "Unsubscribe from feeds not in imported list"
    def import(path)
      error 'File does not exist' unless File.exist?(path)

      require 'feed2email'
      Feed2Email.setup_database
      require 'feed2email/feed'
      require 'feed2email/opml_reader'

      puts "Importing..."

      feeds = File.open(path) {|f| OPMLReader.new(f).urls }

      imported = 0

      feeds.each do |uri|
        if feed = Feed[uri: uri]
          puts "Feed already exists: #{feed}"
        else
          feed = Feed.new(uri: uri)

          if feed.save_without_raising
            puts "Imported feed: #{feed}"
            imported += 1
          else
            puts "Failed to import feed: #{feed}"
          end
        end
      end

      if options[:remove]
        Feed.exclude(uri: feeds).each do |feed|
          if feed.delete
            puts "Removed feed: #{feed}"
          else
            puts "Failed to remove feed: #{feed}"
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
      require 'feed2email'
      Feed2Email.setup_database
      require 'feed2email/feed'

      error 'No feeds' if Feed.empty?

      puts Feed.oldest_first.to_a
      print "\nSubscribed to #{'feed'.pluralize(Feed.count)}"

      if Feed.disabled.any?
        print " (#{Feed.enabled.count} enabled)"
      end

      puts
    end

    desc 'process', 'Process feed subscriptions'
    def process
      require 'feed2email'
      Feed2Email.setup_database(log: true)
      Feed2Email.setup_mail_defaults
      require 'feed2email/feed'

      feeds = Feed.enabled.oldest_first

      if config_data["send_method"] == "smtp"
        with_smtp_connection do |smtp|
          Feed2Email.smtp_connection = smtp
          feeds.each(&:process)
          Feed2Email.smtp_connection = nil
        end
      else
        feeds.each(&:process)
      end
    end

    desc 'remove ID', 'Unsubscribe from feed with id ID'
    def remove(id)
      require 'feed2email'
      Feed2Email.setup_database
      require 'feed2email/feed'

      unless feed = Feed[id]
        error "Feed not found. Is #{id} a valid id?"
      end

      puts "Remove feed: #{feed}"

      if interruptible { yes?('Are you sure?') }
        unless feed.delete
          error 'Failed to remove feed'
        end

        puts 'Removed'
      else
        puts 'Not removed'
      end
    end

    desc 'toggle ID', 'Enable/Disable feed with id ID'
    def toggle(id)
      require 'feed2email'
      Feed2Email.setup_database
      require 'feed2email/feed'

      unless feed = Feed[id]
        error "Feed not found. Is #{id} a valid id?"
      end

      unless feed.toggle
        error 'Failed to toggle feed'
      end

      puts "Toggled feed: #{feed}"
    end

    desc 'uncache ID', 'Clear fetch cache for feed with id ID'
    def uncache(id)
      require 'feed2email'
      Feed2Email.setup_database
      require 'feed2email/feed'

      unless feed = Feed[id]
        error "Feed not found. Is #{id} a valid id?"
      end

      unless feed.uncache
        error 'Failed to uncache feed'
      end

      puts "Uncached feed: #{feed}"
    end

    desc 'version', 'Show feed2email version'
    def version
      puts "feed2email #{VERSION}"
    end

    no_commands do
      def autodiscover_feeds(uri)
        require 'feed2email/feed_autodiscoverer'

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

        response = interruptible {
          ask(
            'Please enter a feed to subscribe to (or Ctrl-C to abort):',
            limited_to: (0...discovered_feeds.size).to_a.map(&:to_s)
          )
        }

        discovered_feeds[response.to_i][:uri]
      end

      def config_data
        Feed2Email.config
      end

      def error(message)
        raise Thor::Error, message
      end

      def interruptible
        begin
          yield
        rescue Interrupt # Ctrl-C
          puts
          exit
        end
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
