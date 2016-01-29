require 'spec_helper'
require 'feed2email/configurable'

describe Feed2Email::Configurable do
  subject do
    Class.new { include Feed2Email::Configurable }.new.config
  end

  describe '#config' do
    it 'delegates the call to Feed2Email' do
      expect(Feed2Email).to receive(:config)
      subject
    end
  end
end
