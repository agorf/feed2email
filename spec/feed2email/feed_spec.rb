require 'spec_helper'
require 'feed2email/feed'
require 'feed2email/entry'

describe Feed2Email::Feed do
  subject(:feed) do
    described_class.create(
      url: url,
      enabled: enabled,
      last_modified: last_modified,
      etag: etag,
    )
  end

  let(:url) { 'https://github.com/agorf/feed2email/commits/master.atom' }

  let(:enabled) { true }

  let(:last_modified) { nil }

  let(:etag) { nil }

  let(:feed_path) { fixture_path('github_feed2email.atom') }

  let(:xml_data) { File.read(feed_path) }

  let(:parsed_feed) { Feedzirra::Feed.parse(xml_data) }

  let(:parsed_entry) { parsed_feed.entries.first }

  let(:entry_url) { parsed_entry.url }

  describe '.disabled' do
    subject { described_class.disabled }

    context 'when feed is disabled' do
      let(:enabled) { false }

      it { is_expected.to include(feed) }
    end

    context 'when feed is enabled' do
      let(:enabled) { true }

      it { is_expected.not_to include(feed) }
    end
  end

  describe '.enabled' do
    subject { described_class.enabled }

    context 'when feed is enabled' do
      let(:enabled) { true }

      it { is_expected.to include(feed) }
    end

    context 'when feed is disabled' do
      let(:enabled) { false }

      it { is_expected.not_to include(feed) }
    end
  end

  describe '.oldest_first' do
    subject { described_class.oldest_first.to_a }

    let(:another_feed) do
      described_class.create(url: 'https://github.com/agorf.atom',
                             created_at: created_at)
    end

    context 'when feed is the oldest' do
      let(:created_at) { feed.created_at + 1 }

      before do
        another_feed # create both feeds
      end

      it { is_expected.to eq [feed, another_feed] }
    end

    context 'when feed is not the oldest' do
      let(:created_at) { feed.created_at - 1 }

      before do
        another_feed # create both feeds
      end

      it { is_expected.to eq [another_feed, feed] }
    end
  end

  describe '#entries' do
    subject { feed.entries }

    context 'when feed has entries' do
      let!(:entry) {
        Feed2Email::Entry.create(feed_id: feed.id, url: entry_url)
      }

      it { is_expected.to eq [entry] }
    end

    context 'when feed has no entries' do
      before do
        feed.entries_dataset.destroy
      end

      it { is_expected.to eq [] }
    end
  end

  describe '#old?' do
    subject { feed.old? }

    context 'when feed has entries' do
      let!(:entry) {
        Feed2Email::Entry.create(feed_id: feed.id, url: entry_url)
      }

      it { is_expected.to eq true }
    end

    context 'when feed has no entries' do
      before do
        feed.entries_dataset.destroy
      end

      it { is_expected.to eq false }
    end
  end

  describe '#process' do
    subject { feed.process }

    let(:logger) { double('logger') }

    before do
      allow(logger).to receive(:error)
      allow(logger).to receive(:info)
      allow(logger).to receive(:debug)
      allow(Feed2Email).to receive(:logger).and_return(logger)
    end

    context 'when feed fetch fails' do
      shared_examples 'feed fetch failure' do |error|
        it 'logs the feed being processed' do
          expect(logger).to receive(:info).with(/\bprocessing feed\b/i)

          subject
        end

        it 'logs the feed being fetched' do
          expect(logger).to receive(:debug).with(/\bfetching feed\b/i)

          subject
        end

        it 'logs the feed fetch failure' do
          expect(logger).to receive(:error).with(/\bfailed to fetch\b/i)

          subject
        end

        it 'logs the error' do
          expect(logger).to receive(:error).with(/\b#{Regexp.escape(error)}\b/)

          subject
        end

        it 'does not send any emails' do
          expect { subject }.
            not_to change { Mail::TestMailer.deliveries.size }.from(0)
        end

        it "does not change feed's last_modified" do
          expect { subject }.
            not_to change { feed.reload.last_modified }.from(nil)
        end

        it "does not change feed's etag" do
          expect { subject }.not_to change { feed.reload.etag }.from(nil)
        end
      end

      context 'due to a connection error' do
        before do
          stub_request(:head, url).to_raise(SocketError)
        end

        it_behaves_like 'feed fetch failure', 'SocketError'
      end

      context 'due to a timeout' do
        before do
          stub_request(:head, url).to_timeout
        end

        it_behaves_like 'feed fetch failure', 'Timeout::Error'
      end

      context 'due to a 404 Not Found HTTP error' do
        before do
          stub_request(:head, url).to_return(status: 404)
        end

        it_behaves_like 'feed fetch failure', 'Net::HTTPNotFound'
      end

      context 'due to a 500 Internal Server Error HTTP error' do
        before do
          stub_request(:head, url).to_return(status: 500)
        end

        it_behaves_like 'feed fetch failure', 'Net::HTTPInternalServerError'
      end
    end
  end

  describe '#save_without_raising' do
    subject { feed.save_without_raising }

    before do
      # Cause save to fail
      def feed.before_save
        false
      end
    end

    it 'does not raise an error' do
      expect { subject }.not_to raise_error
    end

    it { is_expected.to eq nil }
  end

  describe '#to_s' do
    subject { feed.to_s }

    context 'when feed is enabled' do
      let(:enabled) { true }

      context 'and no email has been sent' do
        before do
          feed.entries_dataset.destroy
        end

        it { is_expected.to eq "  #{feed.id} #{feed.url}" }
      end

      context 'and an email has been sent' do
        let!(:entry) do
          Feed2Email::Entry.create(feed_id: feed.id, url: entry_url,
                                   created_at: now, updated_at: now)
        end

        let(:now) { Time.now }

        it { is_expected.to eq "  #{feed.id} #{feed.url} last email at #{now}" }
      end
    end

    context 'when feed is disabled' do
      let(:enabled) { false }

      context 'and no email has been sent' do
        before do
          feed.entries_dataset.destroy
        end

        it { is_expected.to eq "  #{feed.id} DISABLED #{feed.url}" }
      end

      context 'and an email has been sent' do
        let!(:entry) do
          Feed2Email::Entry.create(feed_id: feed.id, url: entry_url,
                                   created_at: now, updated_at: now)
        end

        let(:now) { Time.now }

        it {
          is_expected.
            to eq "  #{feed.id} DISABLED #{feed.url} last email at #{now}"
        }
      end
    end
  end

  describe '#toggle' do
    subject { feed.toggle }

    context 'when feed is enabled' do
      let(:enabled) { true }

      it 'disables the feed' do
        expect { subject }.
          to change { feed.reload.enabled }.from(true).to(false)
      end
    end

    context 'when feed is disabled' do
      let(:enabled) { false }

      it 'enables the feed' do
        expect { subject }.
          to change { feed.reload.enabled }.from(false).to(true)
      end
    end
  end

  describe '#uncache' do
    subject { feed.uncache }

    let(:last_modified) { Time.now.to_s }

    let(:etag) { 'e0aa021e21dddbd6d8cecec71e9cf564' }

    it 'nilifies last_modified' do
      expect { subject }.
        to change { feed.reload.last_modified }.from(last_modified).to(nil)
    end

    it 'nilifies etag' do
      expect { subject }.to change { feed.reload.etag }.from(etag).to(nil)
    end
  end
end
