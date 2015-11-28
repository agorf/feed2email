require 'spec_helper'
require 'feed2email/version'

describe Feed2Email do
  subject { Feed2Email::VERSION }

  it 'has a VERSION constant with a major.minor.patch format' do
    expect(subject).to match /\A\d+\.\d+\.\d+\z/
  end
end
