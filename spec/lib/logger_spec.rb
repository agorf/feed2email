require 'spec_helper'

describe Feed2Email do
  describe 'Logger' do
    subject { logger_instance }

    let(:logger_instance) { Feed2Email::Logger.instance }

    it 'is a singleton' do
      expect { Feed2Email::Logger.new }.to raise_error
      expect(Feed2Email::Logger).to respond_to :instance
      expect(subject).to eq Feed2Email::Logger.instance
    end

    describe '#log' do
      subject { logger_instance.log(severity, message) }

      let(:log_level) { 'info' }

      let(:severity) { :info }

      let(:message) { 'foobar' }

      before do
        config = { 'log_path' => log_path, 'log_level' => log_level }
        config_instance = double('config_instance')
        allow(config_instance).to receive(:config).and_return(config)
        allow(Feed2Email::Config).to \
          receive(:instance).and_return(config_instance)
      end

      context 'logging is disabled' do
        let(:logger) { double('logger') }

        before do
          allow(logger_instance).to receive(:logger).and_return(logger)
        end

        context 'log_path is not set' do
          let(:log_path) { nil }

          it 'does not log' do
            expect(logger).not_to receive(:add)
            subject
          end
        end

        context 'log_path is set' do
          let(:log_path) { false }

          it 'does not log' do
            expect(logger).not_to receive(:add)
            subject
          end
        end
      end

      context 'logging is enabled' do
        before do
          logger_instance.instance_variable_set(:@logger, nil) # hack
        end

        context 'log_path is true' do
          let(:log_path) { true }

          it 'logs to standard output' do
            expect(capture_stdout { subject }).to match \
              /#{severity.upcase} .* #{message}/
          end
        end

        context 'log_path is a path' do
          let(:log_path) { 'spec/fixtures/feed2email.log' }

          let(:log_dir) { File.dirname(log_path) }

          let(:log_data) { File.read(log_path) }

          before do
            FileUtils.mkdir_p(log_dir)
          end

          it 'logs to specified file path' do
            subject
            expect(log_data).to match /#{severity.upcase} .* #{message}/
          end

          context 'severity is invalid' do
            let(:severity) { 'foobar'  }

            it 'throws an exception' do
              expect { subject }.to raise_error
            end
          end

          context 'message is invalid' do
            let(:message) { nil }

            it 'converts it to String and logs it' do
              subject
              expect(log_data).to match /#{severity.upcase} .* #{message}/
            end
          end

          context 'log_level is not set' do
            let(:log_level) { nil }

            context 'INFO message' do
              let(:severity) { :info }

              it 'makes it to the log (level defaults to INFO)' do
                subject
                expect(log_data).to match /#{severity.upcase} .* #{message}/
              end
            end

            context 'DEBUG message' do
              let(:severity) { :debug }

              it 'does not make it to the log (level defaults to INFO)' do
                subject
                expect(log_data).not_to match /#{message}/
              end
            end
          end

          context 'log_level is invalid' do
            let(:log_level) { 'foobar' }

            it 'throws an exception' do
              expect { subject }.to raise_error
            end
          end

          after do
            FileUtils.rm_rf(log_dir)
          end
        end
      end
    end
  end
end
