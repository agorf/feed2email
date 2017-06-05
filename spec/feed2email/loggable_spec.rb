require 'spec_helper'
require 'feed2email/loggable'

describe Feed2Email::Loggable do
  subject do
    klass = described_class
    Class.new { include klass }.new.logger
  end

  describe '#logger' do
    it 'delegates the call to Feed2Email' do
      expect(Feed2Email).to receive(:logger)
      subject
    end
  end
end
