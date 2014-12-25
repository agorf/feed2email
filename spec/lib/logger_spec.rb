require 'spec_helper'
require 'fileutils'

describe Feed2Email::Logger do
  describe '#log' do
    subject { logger.log(severity, message) }

    let(:logger) { Feed2Email::Logger.new(log_path, log_level) }

    let(:log_path) { Tempfile.new('feed2email.log').path }

    let(:log_level) { 'info' }

    let(:severity) { 'info' }

    let(:message) { 'foo' }

    context 'logging is disabled' do
      context 'log_path is not set' do
        let(:log_path) { nil }

        it 'does not log to standard output' do
          expect(capture_stdout { subject }).to be_empty
        end
      end

      context 'log_path is false' do
        let(:log_path) { false }

        it 'does not log to standard output' do
          expect(capture_stdout { subject }).to be_empty
        end
      end
    end

    context 'logging is enabled' do
      context 'log_path is true' do
        let(:log_path) { true }

        it 'logs to standard output' do
          expect(capture_stdout { subject }).to match \
            /#{severity.upcase} .* #{message}/
        end
      end

      context 'log_path is a path' do
        let(:log_path) { Tempfile.new('feed2email.log').path }

        let(:log_data) { File.read(log_path) }

        after do
          FileUtils.rm_f(log_path)
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
      end
    end
  end
end
