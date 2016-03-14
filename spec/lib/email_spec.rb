require 'spec_helper'
require 'feed2email/core_ext'
require 'feed2email/email'
require 'feed2email/version'

describe Feed2Email::Email do
  subject(:email) do
    described_class.new(
      from:      from,
      to:        to,
      subject:   email_subject,
      html_body: html_body,
    )
  end

  let(:from) { 'sender@feed2email.org' }
  let(:to) { 'recipient@feed2email.org' }
  let(:email_subject) { 'This is a subject' }
  let(:html_body) { '<p>This is the <strong>body</strong>.</p>' }

  describe '#deliver!' do
    it 'sends email' do
      expect { subject.deliver! }.to change {
        Mail::TestMailer.deliveries.size }.from(0).to(1)
    end

    describe 'sent email' do
      subject(:delivery) { Mail::TestMailer.deliveries.first }

      before do
        email.deliver!
      end

      it 'has the right sender' do
        expect(subject.from).to eq [from]
      end

      it 'has the right recipient' do
        expect(subject.to).to eq [to]
      end

      it 'has the right subject' do
        expect(subject.subject).to eq email_subject
      end

      it 'is multipart' do
        expect(subject).to be_multipart
      end

      it 'has two parts' do
        expect(subject.parts.size).to eq 2
      end

      describe 'HTML part body' do
        subject do
          delivery.parts.find {|p| p.content_type['text/html'] }.body.raw_source
        end

        it 'contains the passed HTML body' do
          expect(subject).to match(/#{Regexp.escape(html_body)}/)
        end

        it 'mentions feed2email' do
          expect(subject).to match(
            /feed2email\s+#{Regexp.escape(Feed2Email::VERSION)}/)
        end
      end

      describe 'text part body' do
        subject do
          delivery.parts.find {|p| p.content_type['text/plain'] }.body.raw_source
        end

        it 'contains the passed HTML body as Markdown' do
          expect(subject).to match(/#{Regexp.escape(html_body.to_markdown)}/)
        end

        it 'mentions feed2email' do
          expect(subject).to match(
            /feed2email\s+#{Regexp.escape(Feed2Email::VERSION)}/)
        end
      end
    end
  end
end
