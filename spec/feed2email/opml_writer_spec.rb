require 'spec_helper'
require 'feed2email/opml_writer'

describe Feed2Email::OPMLWriter do
  subject { described_class.new(urls) }

  describe '#write' do
    subject { super().write(io) }

    let(:io) { StringIO.new }
    let(:opml) { File.read(fixture_path('feeds.opml')) }
    let(:urls) {
      [
        'https://github.com/agorf.atom',
        'https://github.com/agorf/feed2email/commits/master.atom'
      ]
    }

    before do
      expect(Time).to receive(:now).and_return('2015-12-03 00:20:14 +0200')
      expect(ENV).to receive(:[]).with('USER').and_return('agorf')

      stub_request(:any, urls[0]).to_return(
        body: File.read(fixture_path('github_agorf.atom')),
        headers: { content_type: 'application/atom+xml' }
      )
      stub_request(:any, urls[1]).to_return(
        body: File.read(fixture_path('github_feed2email.atom')),
        headers: { content_type: 'application/atom+xml' }
      )
    end

    it 'returns the number of written bytes' do
      expect(subject).to eq opml.length
    end

    it 'writes OPML to the passed IO object' do
      expect { subject }.to change { io.rewind; io.read }.from('').to(opml)
    end
  end
end
