require 'spec_helper'

describe Feed2Email::Config do
  describe '.load' do
    subject { Feed2Email::Config.load(config_file) }

    let(:config_file) { Tempfile.new('config.yml').path }

    before do
      FileUtils.cp(
        File.join('spec', 'fixtures', 'config', "#{config_template}.yml"),
        config_file
      )
    end

    after do
      FileUtils.rm_f(config_file)
    end

    shared_examples 'an invalid config file' do |error_re, exit_status|
      it 'prints an error message' do
        expect(
          capture_stderr {
            begin
              subject
            rescue SystemExit
            end
          }
        ).to match error_re
      end

      it "exits with an error status of #{exit_status}" do
        status = nil

        expect {
          begin
            subject
          rescue SystemExit => e
            status = e.status
          end
        }.to change {
          status
        }.from(nil).to(exit_status)
      end
    end

    context 'config file is missing' do
      before do
        File.unlink(config_file)
      end

      it_behaves_like 'an invalid config file', /missing .*config file/, 1 do
        let(:config_template) { 'recipient_only' }
      end
    end

    context 'config file is blank' do
      it_behaves_like 'an invalid config file', /invalid .*config file/, 1 do
        let(:config_template) { 'blank' }
      end
    end

    context 'config file contains invalid YAML' do
      it_behaves_like 'an invalid config file', /invalid .*config file/, 1 do
        let(:config_template) { 'invalid_yaml' }
      end
    end

    context 'config file contains valid YAML' do
      context 'has invalid permissions' do
        before do
          File.chmod(0644, config_file) # world-readable
        end

        it_behaves_like 'an invalid config file', /invalid permissions/, 2 do
          let(:config_template) { 'empty' }
        end
      end

      context 'has valid permissions' do
        before do
          File.chmod(0600, config_file) # private
        end

        context 'has no recipient address' do
          it_behaves_like 'an invalid config file', /recipient missing/, 3 do
            let(:config_template) { 'empty' }
          end
        end

        context 'has recipient address' do
          let(:config_template) { 'recipient_only' }

          it 'returns config data' do
            expect(subject).to eq('recipient' => 'foo@bar.com')
          end
        end
      end
    end
  end
end
