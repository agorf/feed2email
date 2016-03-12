require 'spec_helper'
require 'feed2email/configurable'

describe Feed2Email::Configurable do
  subject do
    klass = described_class
    Class.new { include klass }.new.config
  end

  describe '#config' do
    it 'delegates the call to Feed2Email' do
      expect(Feed2Email).to receive(:config)
      subject
    end
  end
end
