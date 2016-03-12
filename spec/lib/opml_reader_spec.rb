require 'spec_helper'
require 'feed2email/opml_reader'

describe Feed2Email::OPMLReader do
  let(:io) { File.open(fixture_path('feeds.opml')) }

  subject { described_class.new(io) }

  describe '#urls' do
    subject { super().urls }

    it 'returns a list of feed URIs' do
      expect(subject).to eq [
        'https://github.com/agorf.atom',
        'https://github.com/agorf/feed2email/commits/master.atom'
      ]
    end
  end
end
