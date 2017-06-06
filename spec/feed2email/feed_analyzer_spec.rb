require 'spec_helper'
require 'feed2email/feed_analyzer'

describe Feed2Email::FeedAnalyzer do
  subject(:analyzer) { described_class.new(url) }

  let(:basename) { 'master' }
  let(:ext) { 'atom' }
  let(:url) { "https://github.com/agorf/feed2email/commits/#{basename}.#{ext}" }
  let(:body) { File.read(fixture_path('github_feed2email.atom')) }
  let(:content_type) { 'application/atom+xml' }

  before do
    stub_request(:any, url).to_return(
      body: body,
      headers: { content_type: content_type }
    )
  end

  describe '#title' do
    subject { analyzer.title }

    it { is_expected.to eq 'Recent Commits to feed2email:master' }

    context 'body is empty' do
      let(:body) { '' }

      it { is_expected.to be_nil }
    end

    context 'body cannot be parsed' do
      let(:body) { 'foobar' }

      it { is_expected.to be_nil }
    end
  end

  describe '#type' do
    subject { analyzer.type }

    context 'content type is text/rss' do
      let(:content_type) { 'text/rss' }

      it { is_expected.to eq 'rss' }
    end

    context 'content type is text/rss+xml' do
      let(:content_type) { 'text/rss+xml' }

      it { is_expected.to eq 'rss' }
    end

    context 'content type is application/rss+xml' do
      let(:content_type) { 'application/rss+xml' }

      it { is_expected.to eq 'rss' }
    end

    context 'content type is application/rdf+xml' do
      let(:content_type) { 'application/rdf+xml' }

      it { is_expected.to eq 'rss' }
    end

    context 'content type is application/xml' do
      let(:content_type) { 'application/xml' }

      it { is_expected.to eq 'rss' }
    end

    context 'content type is text/xml' do
      let(:content_type) { 'text/xml' }

      it { is_expected.to eq 'rss' }
    end

    context 'content type is text/atom' do
      let(:content_type) { 'text/atom' }

      it { is_expected.to eq 'atom' }
    end

    context 'content type is text/atom+xml' do
      let(:content_type) { 'text/atom+xml' }

      it { is_expected.to eq 'atom' }
    end

    context 'content type is application/atom+xml' do
      let(:content_type) { 'application/atom+xml' }

      it { is_expected.to eq 'atom' }
    end

    context 'content type is something else' do
      let(:content_type) { 'text/plain' }

      context 'path ends with .rdf' do
        let(:ext) { 'rdf' }

        it { is_expected.to eq 'rss' }
      end

      context 'path ends with .rss' do
        let(:ext) { 'rss' }

        it { is_expected.to eq 'rss' }
      end

      context 'path ends with .atom' do
        let(:ext) { 'atom' }

        it { is_expected.to eq 'atom' }
      end

      context 'path ends with something else' do
        let(:ext) { 'txt' }

        context 'path basename is rss.xml' do
          let(:basename) { 'rss' }
          let(:ext) { 'xml' }

          it { is_expected.to eq 'rss' }
        end

        context 'path basename is rdf.xml' do
          let(:basename) { 'rdf' }
          let(:ext) { 'xml' }

          it { is_expected.to eq 'rss' }
        end

        context 'path basename is atom.xml' do
          let(:basename) { 'atom' }
          let(:ext) { 'xml' }

          it { is_expected.to eq 'atom' }
        end

        context 'path basename is something else' do
          let(:ext) { 'txt' }

          it { is_expected.to be_nil }
        end
      end
    end
  end
end
