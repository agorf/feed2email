require 'spec_helper'
require 'feedzirra'
require 'feed2email/entry'
require 'feed2email/feed'

describe Feed2Email::Entry do
  let(:feed_path) { fixture_path('github_feed2email.atom') }
  let(:xml_data) { File.read(feed_path) }
  let(:parsed_feed) { Feedzirra::Feed.parse(xml_data) }
  let(:parsed_entry) { parsed_feed.entries.first }

  let(:url) { parsed_entry.url }
  let(:author) { parsed_entry.author }
  let(:content) { parsed_entry.content }
  let(:published) { parsed_entry.published }
  let(:title) { parsed_entry.title.strip }

  let(:feed_title) { parsed_feed.title }
  let(:feed_url) { 'https://github.com/agorf/feed2email/commits/master.atom' }
  let(:feed_last_processed_at) { Time.now }
  let(:feed_send_existing) { false }

  let(:feed) do
    Feed2Email::Feed.create(
      uri: feed_url,
      last_processed_at: feed_last_processed_at,
      send_existing: feed_send_existing,
    )
  end

  subject(:entry) do
    described_class.new(feed_id: feed.id, uri: url).tap do |e|
      e.author     = author
      e.content    = content
      e.published  = published
      e.title      = title
      e.feed_title = feed_title
    end
  end

  let(:logger) { double('logger') }
  let(:config) { {} }

  before do
    allow(logger).to receive(:warn)
    allow(logger).to receive(:debug)
    allow(Feed2Email).to receive(:logger).and_return(logger)

    allow(Feed2Email).to receive(:config).and_return(config)

    described_class.last_email_sent_at = nil
  end

  describe '#process' do
    subject { entry.process }

    context 'with missing data' do
      shared_examples 'missing data' do
        it { is_expected.to be false }

        it 'logs it' do
          expect(logger).to receive(:warn).with(/\bmissing data\b/i)

          subject
        end
      end

      context 'with missing content' do
        let(:content) { nil }

        include_examples 'missing data'
      end

      context 'with missing feed title' do
        let(:feed_title) { nil }

        include_examples 'missing data'
      end

      context 'with missing title' do
        let(:title) { nil }

        include_examples 'missing data'
      end

      context 'with missing url' do
        let(:url) { nil }

        include_examples 'missing data'
      end
    end

    context 'with old entry' do
      before do
        entry.save
      end

      it { is_expected.to be true }

      it 'logs it' do
        expect(logger).to receive(:debug).with(/\bskipping old\b/i)

        subject
      end
    end

    context 'with new feed entry that should be skipped' do
      let(:feed_last_processed_at) { nil }
      let(:feed_send_existing) { false }

      it { is_expected.to be true }

      it 'logs it' do
        expect(logger).to receive(:warn).with(/\bskipping new\b/i)

        subject
      end
    end

    describe 'email sending' do
      before do
        config.merge!(
          'send_delay' => 0,
          'sender'     => 'sender@feed2email.org',
          'recipient'  => 'recipient@feed2email.org',
        )
      end

      describe 'send delay' do
        context 'with send_delay config option set to 0' do
          before do
            config['send_delay'] = 0
          end

          it 'does not sleep' do
            expect(entry).not_to receive(:sleep)

            subject
          end
        end

        context 'with send_delay config option set to greater than 0' do
          before do
            config['send_delay'] = 10
          end

          context 'with send_method config option set to file' do
            before do
              config['send_method'] = 'file'
            end

            it 'does not sleep' do
              expect(entry).not_to receive(:sleep)

              subject
            end
          end

          context 'with send_method config option not set to file' do
            before do
              config['send_method'] = 'smtp'
            end

            context 'with no previously sent email' do
              before do
                described_class.last_email_sent_at = nil
              end

              it 'does not sleep' do
                expect(entry).not_to receive(:sleep)

                subject
              end
            end

            context 'with previously sent email' do
              let(:now) { Time.now }

              before do
                described_class.last_email_sent_at = last_email_sent_at

                allow(Time).to receive(:now).and_return(now)
              end

              context 'sent more than send_delay seconds ago' do
                let(:last_email_sent_at) { now - config['send_delay'] - 1 }

                it 'does not sleep' do
                  expect(entry).not_to receive(:sleep)

                  subject
                end
              end

              context 'sent exactly send_delay seconds ago' do
                let(:last_email_sent_at) { now - config['send_delay'] }

                it 'does not sleep' do
                  expect(entry).not_to receive(:sleep)

                  subject
                end
              end

              context 'sent less than send_delay seconds ago' do
                let(:secs_to_sleep) { 1 }
                let(:last_email_sent_at) { now - config['send_delay'] + secs_to_sleep }

                before do
                  allow(entry).to receive(:sleep)
                end

                it 'sleeps' do
                  expect(entry).to receive(:sleep).with(secs_to_sleep)

                  subject
                end

                it 'logs it' do
                  expect(logger).to receive(:debug).with(/\bsleeping for #{secs_to_sleep.to_f}\b/i)

                  subject
                end
              end
            end
          end
        end
      end

      it 'logs email sending' do
        expect(logger).to receive(:debug).with(/\bsending\b/i)

        subject
      end

      describe 'email building and delivery' do
        let(:now) { Time.now }

        before do
          allow(Time).to receive(:now).and_return(now)
        end

        it 'sets when the last email was sent' do
          expect { subject }.to change {
            described_class.last_email_sent_at }.from(nil).to(now)
        end

        it 'persists the entry record' do
          expect { subject }.to change { entry.new? }.from(true).to(false)
        end

        describe 'sent email' do
          subject(:delivery) { Mail::TestMailer.deliveries.first }

          before do
            entry.process
          end

          it 'has the right sender' do
            expect(subject.from).to eq [config['sender']]
          end

          it 'has the right recipient' do
            expect(subject.to).to eq [config['recipient']]
          end

          it 'has the right subject' do
            expect(subject.subject).to eq title
          end

          it 'is multipart' do
            expect(subject).to be_multipart
          end

          it 'contains the entry content' do
            expect(
              delivery.parts.find {|p| p.content_type['text/html'] }.body.raw_source
            ).to match(%{
              <h1><a href="https://github.com/agorf/feed2email/commit/8a4581aa9e51b5adbaeb22374e5dc8aca0acdefd">Test cached feeds are actually returned</a></h1>
              <pre style='white-space:pre-wrap;width:81ex'>Test cached feeds are actually returned</pre>
              <p>Published by agorf at 2015-12-02 20:29:22 UTC</p>
              <p><a href="https://github.com/agorf/feed2email/commit/8a4581aa9e51b5adbaeb22374e5dc8aca0acdefd">https://github.com/agorf/feed2email/commit/8a4581aa9e51b5adbaeb22374e5dc8aca0acdefd</a></p>
            }.gsub(/^\s+/, ''))
          end
        end

        context 'when delivery fails' do
          before do
            allow_any_instance_of(Feed2Email::Email).to receive(
              :deliver!).and_return(false)
          end

          it 'does not set when the last email was sent' do
            expect { subject }.not_to change {
              described_class.last_email_sent_at }
          end

          it 'does not persist the entry record' do
            expect { subject }.not_to change { entry.new? }
          end
        end
      end
    end
  end
end
