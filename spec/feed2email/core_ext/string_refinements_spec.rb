require 'spec_helper'
require 'feed2email/core_ext/string_refinements'

class RefinedClass
  using Feed2Email::CoreExt::StringRefinements

  def self.blank?(str)
    str.blank?
  end

  def self.escape_html(html)
    html.escape_html
  end

  def self.pluralize(singular, plural, count)
    if plural.nil?
      singular.pluralize(count)
    else
      singular.pluralize(count, plural)
    end
  end

  def self.lstrip_lines(str)
    str.lstrip_lines
  end

  def self.strip_html(html)
    html.strip_html
  end

  def self.to_markdown(html)
    html.to_markdown
  end
end

describe String do
  describe '#blank?' do
    subject { RefinedClass.blank?(str) }

    context 'input is nil' do
      let(:str) { nil }

      it { is_expected.to eq true }
    end

    context 'input is empty' do
      let(:str) { ' ' }

      it { is_expected.to eq true }
    end

    context 'input is neither nil, nor empty' do
      let(:str) { ' foo' }

      it { is_expected.to eq false }
    end
  end

  describe '#escape_html' do
    subject { RefinedClass.escape_html(html) }

    context 'input is &' do
      let(:html) { '&' }

      it { is_expected.to eq '&amp;' }
    end

    context 'input is "' do
      let(:html) { '"' }

      it { is_expected.to eq '&quot;' }
    end

    context 'input is <' do
      let(:html) { '<' }

      it { is_expected.to eq '&lt;' }
    end

    context 'input is >' do
      let(:html) { '>' }

      it { is_expected.to eq '&gt;' }
    end
  end

  describe '#lstrip_lines' do
    subject { RefinedClass.lstrip_lines(text) }

    let(:text) { "\n foo\n \t\rbar\n" }

    it { is_expected.to eq "foo\nbar\n" }
  end

  describe '#pluralize' do
    subject { RefinedClass.pluralize(singular, nil, count) }

    let(:singular) { 'apple' }

    context 'count is 1' do
      let(:count) { 1 }

      it { is_expected.to eq '1 apple' }
    end

    context 'count is greater than 1' do
      let(:count) { 2 }

      it { is_expected.to eq '2 apples' }

      context 'plural is present' do
        subject { RefinedClass.pluralize(singular, 'apples!', count) }

        it { is_expected.to eq '2 apples!' }
      end
    end
  end

  describe '#strip_html' do
    it 'strips HTML' do
      expect(
        RefinedClass.strip_html(
          'You can find feed2email ' +
          '<a href="http://github.com/agorf/feed2email">here</a>.'
        )
      ).to eq 'You can find feed2email here.'
    end
  end

  describe '#to_markdown' do
    subject { RefinedClass.to_markdown(html) }

    let(:html) { File.read(fixture_path('to_markdown.html')) }
    let(:markdown) { File.read(fixture_path('to_markdown.markdown')) }

    it { is_expected.to eq markdown }
  end
end
