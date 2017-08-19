require 'spec_helper'
require 'feed2email'
require 'feed2email/cli'
require 'feed2email/feed'
require 'feed2email/version'

describe Feed2Email::Cli do
  subject(:cli) { described_class.new([], cli_options) }

  let(:cli_options) { {} }

  let(:feed) { Feed2Email::Feed.new(url: feed_url) }

  let(:feed_url) { 'https://github.com/agorf.atom' }

  before do
    allow(Feed2Email).to receive(:setup_database)
  end

  describe '#add' do
    subject { cli.add(add_url) }

    context 'with invalid URL' do
      let(:add_url) { feed_url.sub('.com/', '.invalid/') }

      let(:error) { SocketError.new('getaddrinfo: Name or service not known') }

      before do
        stub_request(:head, add_url).to_raise(error)
      end

      it 'does not add feed' do
        expect { discard_thor_error { subject } }.not_to change {
          Feed2Email::Feed.where(url: feed_url).count }
      end

      it 'raises error with relevant message' do
        expect { subject }.to raise_error(Thor::Error, error.message)
      end
    end

    context 'with valid URL' do
      context 'of a feed' do
        let(:add_url) { feed_url }

        before do
          stub_request(:any, add_url).to_return(
            body: File.read(fixture_path('github_feed2email.atom')),
            headers: { content_type: 'application/rss+xml' }
          )
        end

        context 'and a feed with the same URL already exists' do
          before do
            feed.save
          end

          it 'raises error with relevant message' do
            expect { subject }.to raise_error(Thor::Error,
              "Feed already exists: #{feed}")
          end
        end

        context 'and a feed with the same URL does not exist' do
          before do
            Feed2Email::Feed.where(url: feed_url).delete
          end

          context 'and successful feed save' do
            context 'and without --send-existing option' do
              before do
                cli_options[:send_existing] = false
              end

              it 'adds the feed with the option to false' do
                expect { discard_stdout { subject } }.to change {
                  Feed2Email::Feed.where(url: feed_url, send_existing: false).
                    count
                }.from(0).to(1)
              end

              it 'prints a relevant message' do
                expect { subject }.to output("Added feed:   1 #{feed_url}\n").
                  to_stdout
              end

              context 'and URL has no protocol' do
                let(:add_url) { feed_url.sub(%r{\Ahttps?://}, '') }

                let(:added_url) { "http://#{add_url}" }

                it 'adds the feed with the option to false' do
                  expect { discard_stdout { subject } }.to change {
                    Feed2Email::Feed.where(url: added_url,
                                           send_existing: false).count
                  }.from(0).to(1)
                end
              end
            end

            context 'and with --send-existing option' do
              before do
                cli_options[:send_existing] = true
              end

              it 'adds the feed with the option to true' do
                expect { discard_stdout { subject } }.to change {
                  Feed2Email::Feed.where(url: feed_url, send_existing: true).
                    count
                }.from(0).to(1)
              end

              it 'prints a relevant message' do
                expect { subject }.to output("Added feed:   1 #{feed_url}\n").
                  to_stdout
              end
            end
          end

          context 'and unsuccessful feed save' do
            before do
              allow_any_instance_of(Feed2Email::Feed).to receive(:save).
                and_return(false)
            end

            it 'does not add feed' do
              expect { discard_thor_error { subject } }.not_to change {
                Feed2Email::Feed.where(url: feed_url).count }
            end

            it 'raises error with relevant message' do
              expect { subject }.to raise_error(Thor::Error,
                'Failed to add feed')
            end
          end
        end
      end

      context 'of an HTML page' do
        let(:add_url) { 'https://www.ruby-lang.org/en/' }

        before do
          stub_request(:any, add_url).to_return(
            body: body,
            headers: { content_type: 'text/html' }
          )
        end

        context 'containing no linked feeds' do
          let(:body) { '<html><head></head><body></body></html>' }

          it 'raises error with relevant message' do
            expect { subject }.to raise_error(Thor::Error, 'No feeds found')
          end
        end

        context 'containing a linked feed' do
          let(:body) { File.read(fixture_path('ruby-lang.org.html')) }

          let(:feed_url) { 'https://www.ruby-lang.org/en/feeds/news.rss' }

          context 'and a feed with the same URL already exists' do
            before do
              feed.save
            end

            it 'raises error with relevant message' do
              expect { subject }.to raise_error(Thor::Error,
                'No new feeds found')
            end
          end

          context 'and a feed with the same URL does not exist' do
            before do
              Feed2Email::Feed.where(url: feed_url).delete
            end

            context 'and selection is interrupted' do
              before do
                expect(Thor::LineEditor).to receive(:readline).
                  with('Please enter a feed to subscribe to (or Ctrl-C to abort): [0] ',
                       limited_to: ['0']).and_raise(Interrupt)
              end

              it 'exits' do
                expect { discard_stdout { subject } }.to raise_error(SystemExit)
              end
            end

            context 'and feed is selected' do
              before do
                expect(Thor::LineEditor).to receive(:readline).
                  with('Please enter a feed to subscribe to (or Ctrl-C to abort): [0] ',
                       limited_to: ['0']).and_return('0')

                cli_options[:send_existing] = false
              end

              it 'adds the feed' do
                expect { discard_stdout { subject } }.to change {
                  Feed2Email::Feed.where(url: feed_url).count
                }.from(0).to(1)
              end
            end
          end
        end
      end
    end
  end

  describe '#backend' do
    subject { cli.backend }

    it 'opens the database with the sqlite3 console' do
      expect(cli).to receive('exec').with('sqlite3', Feed2Email.database_path)

      subject
    end
  end

  describe '#config' do
    subject { cli.config }

    context 'EDITOR environmental variable is not set' do
      before do
        ENV.delete('EDITOR')
      end

      it 'raises error with relevant message' do
        expect { subject }.to raise_error(Thor::Error,
          'EDITOR environmental variable not set')
      end
    end

    context 'EDITOR environmental variable is set' do
      before do
        ENV['EDITOR'] = editor
      end

      let(:editor) { 'vim' }

      it 'opens the config file with the editor' do
        expect(cli).to receive('exec').with(editor, Feed2Email.config_path)

        subject
      end
    end
  end

  describe '#export' do
    subject { cli.export(path) }

    let(:path) { File.join(Dir.mktmpdir, 'feeds.opml') }

    shared_examples 'export examples' do |existing_file_data|
      context 'and there are no subscribed feeds' do
        before do
          Feed2Email::Feed.dataset.delete
        end

        it 'raises error with relevant message' do
          expect { subject }.to raise_error(Thor::Error, 'No feeds to export')
        end
      end

      context 'and there is a subscribed feed' do
        before do
          feed.save

          stub_request(:any, feed.url).to_return(
            body: File.read(fixture_path('github_agorf.atom')),
            headers: { content_type: 'application/atom+xml' }
          )
        end

        it 'prints a relevant message with singular form' do
          expect { subject }.to output(
            "Exporting... (this may take a while)\n"\
            "Exported 1 feed subscription to #{path}\n").to_stdout
        end

        context 'and there is another subscribed feed' do
          let!(:another_feed) {
            Feed2Email::Feed.create(url: another_feed_url)
          }

          let(:another_feed_url) {
            'https://github.com/agorf/feed2email/commits/master.atom'
          }

          before do
            expect(Time).to receive(:now).and_return('2015-12-03 00:20:14 +0200')
            expect(ENV).to receive(:[]).with('USER').and_return('agorf')

            stub_request(:any, another_feed.url).to_return(
              body: File.read(fixture_path('github_feed2email.atom')),
              headers: { content_type: 'application/atom+xml' }
            )
          end

          it 'prints a relevant message with plural form' do
            expect { subject }.to output(
              "Exporting... (this may take a while)\n"\
              "Exported 2 feed subscriptions to #{path}\n").to_stdout
          end

          it 'exports feeds as OPML to specified path' do
            expect { discard_stdout { subject } }.to change {
              begin
                File.read(path)
              rescue Errno::ENOENT
              end
            }.from(existing_file_data).to(File.read(fixture_path('feeds.opml')))
          end
        end

        context 'and no bytes are written' do
          before do
            expect_any_instance_of(Feed2Email::OPMLWriter).to receive(:write).
              and_return(0)
          end

          it 'prints a relevant message' do
            expect { subject }.to output(
              "Exporting... (this may take a while)\n"\
              "No feed subscriptions exported\n").to_stdout
          end
        end
      end
    end

    context 'when file already exists' do
      before do
        open(path, 'w') {|f| f.write('foo') }

        expect(Thor::LineEditor).to receive(:readline).with(
          "Overwrite #{path}? (enter \"h\" for help) [Ynaqh] ",
          add_to_history: false).and_return(overwrite_response)
      end

      context 'and overwrite is not confirmed' do
        let(:overwrite_response) { 'n' }

        it 'does not overwrite the file' do
          expect { subject }.not_to change { File.read(path) }
        end
      end

      context 'and overwrite is confirmed' do
        let(:overwrite_response) { 'y' }

        include_examples 'export examples', 'foo'
      end
    end

    context 'when file does not exist' do
      before do
        FileUtils.rm_f(path)
      end

      include_examples 'export examples', nil
    end
  end

  describe '#import' do
    subject { cli.import(path) }

    let(:path) { File.join(Dir.mktmpdir, 'feeds.opml') }

    context 'when the file to import does not exist' do
      before do
        FileUtils.rm_f(path)
      end

      it 'raises an error with a relevant message' do
        expect { subject }.to raise_error(Thor::Error, 'File does not exist')
      end
    end

    context 'when the file to import exists' do
      before do
        FileUtils.cp(fixture_path('feeds.opml'), path)
      end

      context 'and contains an old feed' do
        let!(:old_feed) {
          Feed2Email::Feed.create(url: 'https://github.com/agorf.atom')
        }

        context 'and a new feed' do
          def new_feed_where
            Feed2Email::Feed.where(url: new_feed_url)
          end

          let(:new_feed_url) {
            'https://github.com/agorf/feed2email/commits/master.atom'
          }

          let(:new_feed) { new_feed_where.first }

          before do
            new_feed_where.delete
          end

          context 'and import succeeds' do
            it 'prints a message that importing has started' do
              expect { subject }.to output(/\bImporting\b/).to_stdout
            end

            it 'does not remove the old feed' do
              discard_stdout { subject }

              expect { old_feed.refresh }.not_to raise_error
            end

            it 'prints a message that the old feed exists' do
              expect { subject }.
                to output(/\bFeed already exists: #{old_feed}\s/).to_stdout
            end

            it 'adds the new feed' do
              expect { discard_stdout { subject } }.
                to change { new_feed_where.empty? }.from(true).to(false)
            end

            it 'prints a message that the new feed was imported' do
              expect { subject }.
                to output(/\bImported feed: #{new_feed}\s/).to_stdout
            end

            it 'prints a message about the result of the operation' do
              expect { subject }.to output(
                /\bImported 1 feed subscription from #{path}\b/
              ).to_stdout
            end

            it 'imports the right number of feeds' do
              expect { discard_stdout { subject } }.
                to change(Feed2Email::Feed, :count).from(1).to(2)
            end
          end

          context 'and import fails' do
            before do
              allow_any_instance_of(Feed2Email::Feed).to receive(:save).
                and_return(false)
            end

            it 'prints a message that importing has started' do
              expect { subject }.to output(/\bImporting\b/).to_stdout
            end

            it 'does not remove the old feed' do
              discard_stdout { subject }

              expect { old_feed.refresh }.not_to raise_error
            end

            it 'prints a message that the old feed exists' do
              expect { subject }.
                to output(/\bFeed already exists: #{old_feed}\s/).to_stdout
            end

            it 'does not add the new feed' do
              expect { discard_stdout { subject } }.
                not_to change { new_feed_where.empty? }.from(true)
            end

            it 'prints a message that the new feed was not imported' do
              expect { subject }.to output(
                /\bFailed to import feed: #{new_feed_url}\s/
              ).to_stdout
            end

            it 'prints a message about the result of the operation' do
              expect { subject }.to output(
                /\bNo feed subscriptions imported\b/
              ).to_stdout
            end

            it 'does not import any other feeds' do
              expect { discard_stdout { subject } }.
                not_to change(Feed2Email::Feed, :count).from(1)
            end
          end
        end
      end

      context 'and does not contain an old feed' do
        let(:new_feed_urls) {
          [
            'https://github.com/agorf.atom',
            'https://github.com/agorf/feed2email/commits/master.atom',
          ]
        }

        before do
          Feed2Email::Feed.where(url: new_feed_urls).delete
        end

        context 'and an old feed exists' do
          let(:old_feed_url) { 'https://www.ruby-lang.org/en/feeds/news.rss' }

          let!(:old_feed) { Feed2Email::Feed.create(url: old_feed_url) }

          context 'and there is no --remove option' do
            before do
              cli_options[:remove] = false
            end

            it 'prints a message that importing has started' do
              expect { subject }.to output(/\bImporting\b/).to_stdout
            end

            it 'adds the first feed' do
              expect { discard_stdout { subject } }.to change {
                Feed2Email::Feed.where(url: new_feed_urls[0]).empty?
              }.from(true).to(false)
            end

            it 'prints a message that the first feed was imported' do
              feed = Feed2Email::Feed.where(url: new_feed_urls[0]).first

              expect { subject }.
                to output(/\bImported feed: #{feed}\s/).to_stdout
            end

            it 'adds the second feed' do
              expect { discard_stdout { subject } }.to change {
                Feed2Email::Feed.where(url: new_feed_urls[1]).empty?
              }.from(true).to(false)
            end

            it 'prints a message that the second feed was imported' do
              feed = Feed2Email::Feed.where(url: new_feed_urls[1]).first

              expect { subject }.
                to output(/\bImported feed: #{feed}\s/).to_stdout
            end

            it 'does not remove the old feed' do
              discard_stdout { subject }

              expect { old_feed.refresh }.not_to raise_error
            end

            it 'does not print a message about the old feed' do
              feed = Feed2Email::Feed.where(url: old_feed_url).first

              expect { subject }.not_to output(/#{feed}/).to_stdout
            end

            it 'prints a message about the result of the operation' do
              expect { subject }.to output(
                /\bImported 2 feed subscriptions from #{path}\b/
              ).to_stdout
            end

            it 'imports the right number of feeds' do
              expect { discard_stdout { subject } }.
                to change(Feed2Email::Feed, :count).from(1).to(3)
            end
          end

          context 'and there is a --remove option' do
            before do
              cli_options[:remove] = true
            end

            context 'and removal succeeds' do
              it 'prints a message that importing has started' do
                expect { subject }.to output(/\bImporting\b/).to_stdout
              end

              it 'adds the first feed' do
                expect { discard_stdout { subject } }.to change {
                  Feed2Email::Feed.where(url: new_feed_urls[0]).empty?
                }.from(true).to(false)
              end

              it 'prints a message that the first feed was imported' do
                feed = Feed2Email::Feed.where(url: new_feed_urls[0]).first

                expect { subject }.
                  to output(/\bImported feed: #{feed}\s/).to_stdout
              end

              it 'adds the second feed' do
                expect { discard_stdout { subject } }.to change {
                  Feed2Email::Feed.where(url: new_feed_urls[1]).empty?
                }.from(true).to(false)
              end

              it 'prints a message that the second feed was imported' do
                feed = Feed2Email::Feed.where(url: new_feed_urls[1]).first

                expect { subject }.
                  to output(/\bImported feed: #{feed}\s/).to_stdout
              end

              it 'removes the old feed' do
                discard_stdout { subject }

                expect { old_feed.refresh }.
                  to raise_error(Sequel::Error, 'Record not found')
              end

              it 'prints a message that the old feed was removed' do
                feed = Feed2Email::Feed.where(url: old_feed_url).first

                expect { subject }.
                  to output(/\bRemoved feed: #{feed}\s/).to_stdout
              end

              it 'prints a message about the result of the operation' do
                expect { subject }.to output(
                  /\bImported 2 feed subscriptions from #{path}\b/
                ).to_stdout
              end

              it 'imports the right number of feeds' do
                expect { discard_stdout { subject } }.
                  to change(Feed2Email::Feed, :count).from(1).to(2)
              end
            end

            context 'and removal fails' do
              before do
                allow_any_instance_of(Feed2Email::Feed).to receive(:delete).
                  and_return(false)
              end

              it 'prints a message that importing has started' do
                expect { subject }.to output(/\bImporting\b/).to_stdout
              end

              it 'adds the first feed' do
                expect { discard_stdout { subject } }.to change {
                  Feed2Email::Feed.where(url: new_feed_urls[0]).empty?
                }.from(true).to(false)
              end

              it 'prints a message that the first feed was imported' do
                feed = Feed2Email::Feed.where(url: new_feed_urls[0]).first

                expect { subject }.
                  to output(/\bImported feed: #{feed}\s/).to_stdout
              end

              it 'adds the second feed' do
                expect { discard_stdout { subject } }.to change {
                  Feed2Email::Feed.where(url: new_feed_urls[1]).empty?
                }.from(true).to(false)
              end

              it 'prints a message that the second feed was imported' do
                feed = Feed2Email::Feed.where(url: new_feed_urls[1]).first

                expect { subject }.
                  to output(/\bImported feed: #{feed}\s/).to_stdout
              end

              it 'does not remove the old feed' do
                discard_stdout { subject }

                expect { old_feed.refresh }.not_to raise_error
              end

              it 'prints a message that the old feed was not removed' do
                feed = Feed2Email::Feed.where(url: old_feed_url).first

                expect { subject }.
                  to output(/\bFailed to remove feed: #{feed}\s/).to_stdout
              end

              it 'prints a message about the result of the operation' do
                expect { subject }.to output(
                  /\bImported 2 feed subscriptions from #{path}\b/
                ).to_stdout
              end

              it 'imports the right number of feeds' do
                expect { discard_stdout { subject } }.
                  to change(Feed2Email::Feed, :count).from(1).to(3)
              end
            end
          end
        end

        context 'and an old feed does not exist' do
          before do
            Feed2Email::Feed.dataset.delete
          end

          it 'prints a message that importing has started' do
            expect { subject }.to output(/\bImporting\b/).to_stdout
          end

          it 'adds the first feed' do
            expect { discard_stdout { subject } }.to change {
              Feed2Email::Feed.where(url: new_feed_urls[0]).empty?
            }.from(true).to(false)
          end

          it 'prints a message that the first feed was imported' do
            feed = Feed2Email::Feed.where(url: new_feed_urls[0]).first

            expect { subject }.to output(/\bImported feed: #{feed}\s/).to_stdout
          end

          it 'adds the second feed' do
            expect { discard_stdout { subject } }.to change {
              Feed2Email::Feed.where(url: new_feed_urls[1]).empty?
            }.from(true).to(false)
          end

          it 'prints a message that the second feed was imported' do
            feed = Feed2Email::Feed.where(url: new_feed_urls[1]).first

            expect { subject }.to output(/\bImported feed: #{feed}\s/).to_stdout
          end

          it 'prints a message about the result of the operation' do
            expect { subject }.to output(
              /\bImported 2 feed subscriptions from #{path}\b/
            ).to_stdout
          end

          it 'imports the right number of feeds' do
            expect { discard_stdout { subject } }.
              to change(Feed2Email::Feed, :count).from(0).to(2)
          end
        end
      end
    end
  end

  describe '#list' do
    subject { cli.list }

    context 'when there are no subscribed feeds' do
      before do
        Feed2Email::Feed.dataset.delete
      end

      it 'raises error with relevant message' do
        expect { subject }.to raise_error(Thor::Error, 'No feeds')
      end
    end

    context 'when there is a subscribed feed' do
      before do
        feed.save
      end

      it 'prints the feeds and their count' do
        expect { subject }.to output(
          "#{feed}\n"\
          "\n"\
          "Subscribed to 1 feed\n"
        ).to_stdout
      end

      context 'and another feed' do
        let!(:another_feed) { Feed2Email::Feed.create(url: another_feed_url) }

        let(:another_feed_url) { 'https://www.ruby-lang.org/en/feeds/news.rss' }

        it 'prints the feeds oldest-first and their count' do
          expect { subject }.to output(
            "#{feed}\n"\
            "#{another_feed}\n"\
            "\n"\
            "Subscribed to 2 feeds\n"
          ).to_stdout
        end

        context 'that is disabled' do
          before do
            another_feed.toggle
          end

          it 'prints the feeds oldest-first and their total/enabled count' do
            expect { subject }.to output(
              "#{feed}\n"\
              "#{another_feed}\n"\
              "\n"\
              "Subscribed to 2 feeds (1 enabled)\n"
            ).to_stdout
          end
        end
      end
    end
  end

  describe '#remove' do
    subject { cli.remove(id) }

    context 'with invalid feed id' do
      let(:id) { 100_000_000 }

      it 'raises error with relevant message' do
        expect { subject }.to raise_error(Thor::Error,
          "Feed not found. Is #{id} a valid id?")
      end
    end

    context 'with valid feed id' do
      let(:id) { feed.id }

      before do
        feed.save
      end

      context 'and removal is interrupted' do
        before do
          expect(Thor::LineEditor).to receive(:readline).with(
            'Are you sure? ', add_to_history: false).and_raise(Interrupt)
        end

        it 'exits' do
          expect { discard_stdout { subject } }.to raise_error(SystemExit)
        end
      end

      context 'and removal is not confirmed' do
        before do
          expect(Thor::LineEditor).to receive(:readline).with(
            'Are you sure? ', add_to_history: false).and_return('n')
        end

        it 'does not remove feed' do
          discard_stdout { subject }

          expect { feed.refresh }.not_to raise_error
        end

        it 'prints a relevant message' do
          expect { subject }.to output("Remove feed: #{feed}\nNot removed\n").
            to_stdout
        end
      end

      context 'and removal is confirmed' do
        before do
          expect(Thor::LineEditor).to receive(:readline).with(
            'Are you sure? ', add_to_history: false).and_return('y')
        end

        context 'and unsuccessful removal' do
          before do
            allow_any_instance_of(Feed2Email::Feed).to receive(:delete).
              and_return(false)
          end

          it 'raises error with relevant message' do
            expect { discard_stdout { subject } }.to raise_error(Thor::Error,
              'Failed to remove feed')
          end
        end

        context 'and successful removal' do
          it 'removes feed' do
            discard_stdout { subject }

            expect { feed.refresh }.to raise_error(Sequel::Error,
              'Record not found')
          end

          it 'prints a relevant message' do
            expect { subject }.to output("Remove feed: #{feed}\nRemoved\n").
              to_stdout
          end
        end
      end
    end
  end

  describe '#toggle' do
    subject { cli.toggle(id) }

    context 'with invalid feed id' do
      let(:id) { 100_000_000 }

      it 'raises error with relevant message' do
        expect { subject }.to raise_error(Thor::Error,
          "Feed not found. Is #{id} a valid id?")
      end
    end

    context 'with valid feed id' do
      let(:id) { feed.id }

      before do
        feed.save
      end

      context 'and unsuccessful toggle' do
        before do
          allow_any_instance_of(Feed2Email::Feed).to receive(:update).
            with(enabled: false).and_return(false)
        end

        it 'raises error with relevant message' do
          expect { subject }.to raise_error(Thor::Error,
            'Failed to toggle feed')
        end
      end

      context 'and successful toggle' do
        context 'and enabled feed' do
          before do
            feed.update(enabled: true)
          end

          it 'disables it' do
            expect { discard_stdout { subject } }.to change {
              feed.refresh.enabled }.from(true).to(false)
          end

          it 'prints a relevant message' do
            expect { subject }.to output { "Toggled feed: #{feed}\n" }.to_stdout
          end
        end

        context 'and disabled feed' do
          before do
            feed.update(enabled: false)
          end

          it 'enables it' do
            expect { discard_stdout { subject } }.to change {
              feed.refresh.enabled }.from(false).to(true)
          end

          it 'prints a relevant message' do
            expect { subject }.to output { "Toggled feed: #{feed}\n" }.to_stdout
          end
        end
      end
    end
  end

  describe '#uncache' do
    subject { cli.uncache(id) }

    context 'with invalid feed id' do
      let(:id) { 100_000_000 }

      it 'raises error with relevant message' do
        expect { subject }.to raise_error(Thor::Error,
          "Feed not found. Is #{id} a valid id?")
      end
    end

    context 'with valid feed id' do
      let(:id) { feed.id }

      before do
        feed.save
      end

      context 'and unsuccessful uncache' do
        before do
          allow_any_instance_of(Feed2Email::Feed).to receive(:update).
            with(last_modified: nil, etag: nil).and_return(false)
        end

        it 'raises error with relevant message' do
          expect { subject }.to raise_error(Thor::Error,
            'Failed to uncache feed')
        end
      end

      context 'and successful uncache' do
        context 'and cached feed' do
          before do
            feed.update(etag: etag, last_modified: last_modified)
          end

          let(:etag) { 'etag' }
          let(:last_modified) { Time.now.to_s }

          it 'uncaches it' do
            expect { discard_stdout { subject } }.to change {
              feed.refresh.etag
            }.from(etag).to(nil).and change {
              feed.refresh.last_modified
            }.from(last_modified).to(nil)
          end

          it 'prints a relevant message' do
            expect { subject }.to output("Uncached feed: #{feed}\n").to_stdout
          end
        end

        context 'and uncached feed' do
          before do
            feed.uncache
          end

          it 'remains uncached' do
            expect { discard_stdout { subject } }.not_to change {
              feed.refresh
              [feed.etag, feed.last_modified]
            }
          end

          it 'prints a relevant message' do
            expect { subject }.to output("Uncached feed: #{feed}\n").to_stdout
          end
        end
      end
    end
  end

  describe '#version' do
    subject { cli.version }

    it 'prints the feed2email version' do
      expect { subject }.to output("feed2email #{Feed2Email::VERSION}\n").
        to_stdout
    end
  end
end
