require 'spec_helper'

describe String do
  describe '#escape_html' do
    it 'escapes &' do
      expect('&'.escape_html).to eq '&amp;'
    end

    it 'escapes "' do
      expect('"'.escape_html).to eq '&quot;'
    end

    it 'escapes <' do
      expect('<'.escape_html).to eq '&lt;'
    end

    it 'escapes >' do
      expect('>'.escape_html).to eq '&gt;'
    end
  end

  describe '#strip_html' do
    it 'strips HTML' do
      expect((
        'You can find feed2email ' +
        '<a href="http://github.com/agorf/feed2email">here</a>.'
      ).strip_html).to eq 'You can find feed2email here.'
    end
  end
end

describe Time do
  describe '#past?' do
    it 'returns true if time is in the past' do
      expect((Time.now - 60).past?).to be_true
    end

    it 'returns false if time is not in the past' do
      expect((Time.now + 60).past?).to be_false
    end
  end
end
