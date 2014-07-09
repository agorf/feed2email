require 'spec_helper'

describe Feed2Email do
  it 'has a VERSION constant' do
    expect { Feed2Email::VERSION }.not_to raise_error
    expect(Feed2Email::VERSION).to match /\A\d+\.\d+\.\d+\z/
  end
end
