require 'spec_helper'
require 'feed2email/feed_autodiscoverer'

describe Feed2Email::FeedAutodiscoverer do
  subject(:discoverer) { described_class.new(uri) }

  let(:uri) { 'https://www.ruby-lang.org/en/' }
  let(:body) { File.read(fixture_path('ruby-lang.org.html')) }
  let(:content_type) { 'text/html' }

  before do
    stub_request(:any, uri).to_return(
      body: body,
      headers: { content_type: content_type }
    )
  end

  describe '#discoverable?' do
    subject { discoverer.discoverable? }

    it { is_expected.to be true }

    context '<head> is missing' do
      let(:body) { '<html><body></body></html>' }

      it { is_expected.to be false }
    end

    context 'content type is not text/html' do
      let(:content_type) { 'text/plain' }

      it { is_expected.to be false }
    end
  end

  describe '#feeds' do
    subject { discoverer.feeds }

    let(:feeds) {
      [
        described_class::DiscoveredFeed.new(
          feed_uri,
          'application/rss+xml',
          'Recent News (RSS)'
        )
      ]
    }

    let(:feed_uri) { 'https://www.ruby-lang.org/en/feeds/news.rss' }

    it { is_expected.to eq feeds }

    context 'not discoverable' do
      let(:content_type) { 'text/plain' }

      it { is_expected.to be_empty }
    end

    context 'feed URI is absolute' do
      before do
        body.sub!('/en/feeds/news.rss', feed_uri)
      end

      it { is_expected.to eq feeds }
    end

    context '<base> is present' do
      let(:base) { 'http://agorf.gr/' } # dummy to ensure it's taken into account
      let(:feed_uri) { URI.join(base, '/en/feeds/news.rss').to_s }

      before do
        body.sub!('<head>', %Q{<head><base href="#{base}">})
      end

      it { is_expected.to eq feeds }
    end
  end
end
