require 'spec_helper'
require 'feed2email'
require 'feed2email/cli'
require 'feed2email/feed'
require 'feed2email/version'

describe Feed2Email::Cli do
  subject(:cli) { described_class.new }

  let(:feed_url) { 'https://github.com/agorf/feed2email/commits/master.atom' }
  let(:feed) { Feed2Email::Feed.create(uri: feed_url) }

  before do
    allow(Feed2Email).to receive(:setup_database)
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
          "EDITOR environmental variable not set")
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

      context 'and unsuccessful toggle' do
        before do
          allow(Feed2Email::Feed).to receive(:[]).with(id).and_return(feed)
          allow(feed).to receive(:toggle).and_return(false)
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
            expect { subject }.to output(
              "Toggled feed:   1 DISABLED https://github.com/agorf/feed2email/commits/master.atom\n"
            ).to_stdout
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
            expect { subject }.to output(
              "Toggled feed:   1 https://github.com/agorf/feed2email/commits/master.atom\n"
            ).to_stdout
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

      context 'and unsuccessful uncache' do
        before do
          allow(Feed2Email::Feed).to receive(:[]).with(id).and_return(feed)
          allow(feed).to receive(:uncache).and_return(false)
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
              feed.refresh
              [feed.etag, feed.last_modified]
            }.from([etag, last_modified]).to([nil, nil])
          end

          it 'prints a relevant message' do
            expect { subject }.to output(
              "Uncached feed:   1 https://github.com/agorf/feed2email/commits/master.atom\n"
            ).to_stdout
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
            expect { subject }.to output(
              "Uncached feed:   1 https://github.com/agorf/feed2email/commits/master.atom\n"
            ).to_stdout
          end
        end
      end
    end
  end

  describe '#version' do
    subject { cli.version }

    it 'prints the feed2email version' do
      expect { subject }.to output(
        "feed2email #{Feed2Email::VERSION}\n").to_stdout
    end
  end
end
