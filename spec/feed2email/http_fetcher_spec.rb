require 'spec_helper'
require 'feed2email/http_fetcher'

describe Feed2Email::HTTPFetcher do
  subject(:fetcher) { described_class.new(url) }

  let(:url) { 'http://github.com/agorf/feed2email' }

  let(:uri) { URI.parse(url) }

  describe '#initialize' do
    it 'adds URL to followed locations' do
      expect(subject.url).to eq url
    end

    context 'without options' do
      it 'sets request_headers to be empty' do
        expect(subject.request_headers).to eq({})
      end

      it 'sets max_redirects to 3' do
        expect(subject.max_redirects).to eq 3
      end

      it 'sets headers_only to false' do
        expect(subject.headers_only).to be false
      end
    end

    context 'with options' do
      subject {
        described_class.new(
          url,
          request_headers: request_headers,
          max_redirects:   max_redirects,
          headers_only:    headers_only,
        )
      }

      let(:request_headers) do
        { 'X-Foo' => 'Bar' }
      end

      let(:max_redirects) { 4 }

      let(:headers_only) { true }

      it 'sets request_headers' do
        expect(subject.request_headers).to eq request_headers
      end

      it 'sets max_redirects' do
        expect(subject.max_redirects).to eq max_redirects
      end

      it 'sets headers_only' do
        expect(subject.headers_only).to eq headers_only
      end
    end
  end

  describe 'accessors' do
    describe 'headers_only' do
      it 'sets and returns headers_only' do
        expect {
          subject.headers_only = true
        }.to change(subject, :headers_only).from(false).to(true)
      end
    end

    describe 'max_redirects' do
      it 'sets and returns max_redirects' do
        expect {
          subject.max_redirects += 1
        }.to change(subject, :max_redirects).by(1)
      end
    end

    describe 'request_headers' do
      it 'sets and returns request_headers' do
        expect {
          subject.request_headers = { 'X-Foo' => 'Bar' }
        }.to change(subject, :request_headers).from({}).to('X-Foo' => 'Bar')
      end
    end
  end

  context 'with some valid redirects' do
    let(:body) { 'OK' }

    let(:content_type) { 'text/plain' }

    let(:locations) do
      [
        'http://a.com/',
        'http://b.com/',
        'http://c.com/',
        'http://d.com/',
      ]
    end

    let(:url) { locations.first }

    before do
      stub_redirects(locations)
      stub_request(:any, locations.last).to_return(
        status:  200,
        body:    body,
        headers: { content_type: content_type }
      )
    end

    describe '#content_type' do
      subject { super().content_type }

      it { is_expected.to eq content_type }
    end

    describe '#data' do
      subject { super().data }

      it { is_expected.to eq body }
    end

    describe '#response' do
      subject { super().response }

      it 'sets response' do
        expect(subject).to be
      end

      it 'follows the redirects' do
        expect { subject }.to change(fetcher, :url).from(url).to(locations.last)
      end

      context 'already called' do
        before do
          subject
          WebMock.reset!
        end

        it 'memoizes the response' do
          expect(a_request(:head, locations.last)).not_to have_been_made
          fetcher.response # subject is already evaluated and wouldn't call #response here
        end
      end
    end

    describe '#uri' do
      subject { super().uri }

      it { is_expected.to eq uri }
    end

    describe '#uri_path' do
      subject { super().uri_path }

      it { is_expected.to eq uri.path }
    end
  end

  context 'with missing location' do
    before do
      stub_request(:head, url).to_return(status: 301)
    end

    describe '#content_type' do
      subject do
        -> { fetcher.content_type }
      end

      it { is_expected.to raise_error described_class::MissingLocation }
    end

    describe '#data' do
      subject do
        -> { fetcher.data }
      end

      it { is_expected.to raise_error described_class::MissingLocation }
    end

    describe '#response' do
      subject do
        -> { fetcher.response }
      end

      it { is_expected.to raise_error described_class::MissingLocation }
    end
  end

  context 'with invalid location' do
    before do
      stub_redirects([url, 'file:///etc/passwd'])
    end

    describe '#content_type' do
      subject do
        -> { fetcher.content_type }
      end

      it { is_expected.to raise_error described_class::InvalidLocation }
    end

    describe '#data' do
      subject do
        -> { fetcher.data }
      end

      it { is_expected.to raise_error described_class::InvalidLocation }
    end

    describe '#response' do
      subject do
        -> { fetcher.response }
      end

      it { is_expected.to raise_error described_class::InvalidLocation }
    end
  end

  context 'with circular redirects' do
    let(:locations) do
      [
        'http://a.com/',
        'http://b.com/',
        'http://c.com/',
        'http://a.com/',
      ]
    end

    let(:url) { locations.first }

    before do
      stub_redirects(locations)
    end

    describe '#content_type' do
      subject do
        -> { fetcher.content_type }
      end

      it { is_expected.to raise_error described_class::CircularRedirects }
    end

    describe '#data' do
      subject do
        -> { fetcher.data }
      end

      it { is_expected.to raise_error described_class::CircularRedirects }
    end

    describe '#response' do
      subject do
        -> { fetcher.response }
      end

      it { is_expected.to raise_error described_class::CircularRedirects }
    end
  end

  context 'with too many redirects' do
    let(:locations) do
      [
        'http://a.com/',
        'http://b.com/',
        'http://c.com/',
        'http://d.com/',
        'http://e.com/',
      ]
    end

    let(:url) { locations.first }

    before do
      stub_redirects(locations)
    end

    describe '#content_type' do
      subject do
        -> { fetcher.content_type }
      end

      it { is_expected.to raise_error described_class::TooManyRedirects }
    end

    describe '#data' do
      subject do
        -> { fetcher.data }
      end

      it { is_expected.to raise_error described_class::TooManyRedirects }
    end

    describe '#response' do
      subject do
        -> { fetcher.response }
      end

      it { is_expected.to raise_error described_class::TooManyRedirects }
    end
  end
end
