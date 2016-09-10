require 'spec_helper'
require 'feed2email'
require 'feed2email/cli'
require 'feed2email/feed'
require 'feed2email/version'

describe Feed2Email::Cli do
  subject(:cli) { described_class.new([], cli_options) }

  let(:cli_options) { {} }

  let(:feed) { Feed2Email::Feed.new(uri: feed_url) }

  let(:feed_url) { 'https://github.com/agorf/feed2email/commits/master.atom' }

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
          Feed2Email::Feed.where(uri: feed_url).count }
      end

      it 'raises error with relevant message' do
        expect { subject }.to raise_error(Thor::Error).with_message(
          error.message)
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
            expect { subject }.to raise_error(Thor::Error).with_message(
              /\bFeed already exists\b/)
          end
        end

        context 'and a feed with the same URL does not exist' do
          before do
            Feed2Email::Feed.where(uri: feed_url).delete
          end

          context 'and successful feed save' do
            context 'and without --send-existing option' do
              before do
                cli_options[:send_existing] = false
              end

              it 'adds the feed with the option to false' do
                expect { discard_output { subject } }.to change {
                  Feed2Email::Feed.where(uri: feed_url, send_existing: false).
                    count
                }.from(0).to(1)
              end

              it 'prints a relevant message' do
                expect { subject }.to output("Added feed:   1 #{feed_url}\n").
                  to_stdout
              end
            end

            context 'and with --send-existing option' do
              before do
                cli_options[:send_existing] = true
              end

              it 'adds the feed with the option to true' do
                expect { discard_output { subject } }.to change {
                  Feed2Email::Feed.where(uri: feed_url, send_existing: true).
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
                Feed2Email::Feed.where(uri: feed_url).count }
            end

            it 'raises error with relevant message' do
              expect { subject }.to raise_error(Thor::Error).with_message(
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
            expect { subject }.to raise_error(Thor::Error).with_message(
              'No feeds found')
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
              expect { subject }.to raise_error(Thor::Error).with_message(
                'No new feeds found')
            end
          end

          context 'and a feed with the same URL does not exist' do
            before do
              Feed2Email::Feed.where(uri: feed_url).delete
            end

            context 'and selection is interrupted' do
              before do
                expect(Thor::LineEditor).to receive(:readline).
                  with('Please enter a feed to subscribe to (or Ctrl-C to abort): [0] ',
                       limited_to: ['0']).and_raise(Interrupt)
              end

              it 'exits' do
                expect { discard_output { subject } }.to raise_error(SystemExit)
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
                expect { discard_output { subject } }.to change {
                  Feed2Email::Feed.where(uri: feed_url).count
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
        expect { subject }.to raise_error(Thor::Error).with_message(
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

  describe '#remove' do
    subject { cli.remove(id) }

    context 'with invalid feed id' do
      let(:id) { 100_000_000 }

      it 'raises error with relevant message' do
        expect { subject }.to raise_error(Thor::Error).with_message(
          "Feed not found. Is #{id} a valid id?")
      end
    end

    context 'with valid feed id' do
      let(:id) { feed.id }

      before do
        feed.save

        expect(Thor::LineEditor).to receive(:readline).with(
          'Are you sure? ', add_to_history: false
        ).and_return(removal_confirmation)
      end

      context 'and unconfirmed removal' do
        let(:removal_confirmation) { 'n' }

        it 'does not remove feed' do
          discard_output { subject }

          expect { feed.refresh }.not_to raise_error
        end

        it 'prints a relevant message' do
          expect { subject }.to output("Remove feed: #{feed}\nNot removed\n").
            to_stdout
        end
      end

      context 'and confirmed removal' do
        let(:removal_confirmation) { 'y' }

        context 'and unsuccessful removal' do
          before do
            allow_any_instance_of(Feed2Email::Feed).to receive(:delete).
              and_return(false)
          end

          it 'raises error with relevant message' do
            expect { discard_output { subject } }.to raise_error(
              Thor::Error).with_message('Failed to remove feed')
          end
        end

        context 'and successful removal' do
          it 'removes feed' do
            discard_output { subject }

            expect { feed.refresh }.to raise_error(Sequel::Error).with_message(
              /Record not found/)
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
        expect { subject }.to raise_error(Thor::Error).with_message(
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
          expect { subject }.to raise_error(Thor::Error).with_message(
            'Failed to toggle feed')
        end
      end

      context 'and successful toggle' do
        context 'and enabled feed' do
          before do
            feed.update(enabled: true)
          end

          it 'disables it' do
            expect { discard_output { subject } }.to change {
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
            expect { discard_output { subject } }.to change {
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
        expect { subject }.to raise_error(Thor::Error).with_message(
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
          expect { subject }.to raise_error(Thor::Error).with_message(
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
            expect { discard_output { subject } }.to change {
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
            feed.update(etag: nil, last_modified: nil)
          end

          it 'remains uncached' do
            expect { discard_output { subject } }.not_to change {
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
