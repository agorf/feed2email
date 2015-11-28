require 'spec_helper'
require 'feed2email/opml_writer'

describe Feed2Email::OPMLWriter do
  subject(:opml_writer) { Feed2Email::OPMLWriter.new(uris) }

  describe '#write' do
    subject { opml_writer.write(io) }

    let(:io) { StringIO.new }
    let(:opml) { File.read(File.join(%w{spec fixtures feeds.opml})) }
    let(:uris) {
      [
        'https://github.com/agorf.atom',
        'https://github.com/agorf/feed2email/commits/master.atom'
      ]
    }

    before do
      expect(Time).to receive(:now).and_return('2015-11-28 17:32:00 +0200')
      expect(ENV).to receive(:[]).with('USER').and_return('agorf')
      expect(opml_writer).to receive(:feed_type).with(uris[0]).and_return('atom')
      expect(opml_writer).to receive(:feed_type).with(uris[1]).and_return('atom')
    end

    it 'returns the number of written bytes' do
      expect(subject).to eq opml.length
    end

    it 'writes OPML to the passed IO object' do
      expect { subject }.to change { io.rewind; io.read }.from('').to(opml)
    end
  end
end
