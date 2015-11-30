require 'spec_helper'
require 'feed2email/redirection_checker'

describe Feed2Email::RedirectionChecker do
  subject(:checker) { Feed2Email::RedirectionChecker.new(checked_uri) }

  let(:checked_uri) { 'http://github.com/agorf/feed2email' } # HTTP
  let(:location) { 'https://github.com/agorf/feed2email' } # HTTPS
  let(:status) { 301 } # permanent

  before do
    stub_request(:head, checked_uri).to_return(
      status: status, headers: { location: location }
    )
  end

  describe '#location' do
    it 'returns the redirection location' do
      expect {
        subject.permanently_redirected?
      }.to change(subject, :location).from(nil).to(location)
    end
  end

  describe '#permanently_redirected?' do
    subject { checker.permanently_redirected? }

    it { is_expected.to be true }

    context 'not redirected' do
      let(:status) { 200 }

      it { is_expected.to be false }
    end

    context 'location matches checked URI' do
      let(:location) { checked_uri }

      it { is_expected.to be false }
    end

    context 'location is invalid' do
      let(:location) { 'ftp://ftp.ntua.gr/' }

      it { is_expected.to be false }
    end
  end
end
