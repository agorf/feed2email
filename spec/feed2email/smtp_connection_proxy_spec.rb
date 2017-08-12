require 'spec_helper'
require 'feed2email/smtp_connection_proxy'

describe Feed2Email::SMTPConnectionProxy do
  subject(:proxy) { described_class.new(smtp, &start_smtp) }

  let(:smtp) { double('smtp', started?: smtp_started) }

  let(:smtp_started) { false }

  let(:start_smtp) { Proc.new {} }

  describe '#smtp' do
    subject { proxy.smtp }

    it { is_expected.to eq smtp }
  end

  describe 'delegation' do
    let(:message) { 'Hello, world!' }

    let(:sender) { 'sender@feed2email.org' }

    let(:recipients) { ['recipient@feed2email.org'] }

    before do
      allow(smtp).to receive(:send_message).with(message, sender, recipients)
    end

    context 'when there is no SMTP connection' do
      let(:smtp_started) { false }

      it 'sets it up' do
        expect(start_smtp).to receive(:call).with(smtp)

        proxy.send_message(message, sender, recipients)
      end

      it 'delegates the call to the SMTP connection object' do
        expect(smtp).to receive(:send_message).with(message, sender, recipients)

        proxy.send_message(message, sender, recipients)
      end
    end

    context 'when there is an SMTP connection' do
      let(:smtp_started) { true }

      it 'does not try to set it up again' do
        expect(start_smtp).not_to receive(:call).with(smtp)

        proxy.send_message(message, sender, recipients)
      end

      it 'delegates the call to the SMTP connection object' do
        expect(smtp).to receive(:send_message).with(message, sender, recipients)

        proxy.send_message(message, sender, recipients)
      end
    end
  end
end
