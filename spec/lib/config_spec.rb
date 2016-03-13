require 'fileutils'
require 'yaml'
require 'spec_helper'
require 'feed2email/config'

describe Feed2Email::Config do
  let(:config_path) { File.join(*%w{tmp home config.yml}) }

  subject { described_class.new(config_path) }

  before do
    FileUtils.rm_f(config_path)
  end

  it 'has a SEND_METHODS constant' do
    expect { described_class::SEND_METHODS }.not_to raise_error
  end

  describe 'config delegations' do
    let(:config) { double('config') }

    before do
      allow(subject).to receive(:config).and_return(config)
    end

    it 'delegates #[] to #config' do
      expect(config).to receive(:[]).with('send_method')
      subject['send_method']
    end

    it 'delegates #keys to #config' do
      expect(config).to receive(:keys)
      subject.keys
    end

    it 'delegates #slice to #config' do
      expect(config).to receive(:slice)
      subject.slice
    end
  end

  context 'when config does not exist' do
    before do
      FileUtils.rm_f(config_path)
    end

    it 'gets created' do
      expect { subject }.to change {
        File.exist?(config_path) }.from(false).to(true)
    end

    it 'has correct permissions' do
      subject
      expect('%o' % (File.stat(config_path).mode & 0777)).to eq '600'
    end

    it 'contains the defaults' do
      subject

      expect(YAML.safe_load(File.read(config_path))).to eq(
        'log_level'       => 'info',
        'log_path'        => true,
        'log_shift_age'   => 0,
        'log_shift_size'  => 1,
        'mail_path'       => File.join(ENV['HOME'], 'Mail'),
        'max_entries'     => 20,
        'send_delay'      => 10,
        'send_exceptions' => false,
        'send_method'     => 'file',
        'sendmail_path'   => '/usr/sbin/sendmail',
        'smtp_auth'       => 'login',
        'smtp_starttls'   => true,
      )
    end
  end

  context 'when config exists' do
    subject { super()['send_method'] }

    before do
      FileUtils.touch(config_path)
    end

    it 'raises error about permissions' do
      expect { subject }.to raise_error(
        described_class::InvalidConfigPermissionsError)
    end

    context 'when it has correct permissions' do
      before do
        FileUtils.chmod(0600, config_path)
      end

      it 'raises error about type of data' do
        expect { subject }.to raise_error(
          described_class::InvalidConfigDataTypeError)
      end

      context 'when it has correct type of data' do
        let(:config_data) do
          {}
        end

        before do
          open(config_path, 'w') {|f| f << config_data.to_yaml }
        end

        it 'raises error about recipient option missing' do
          expect { subject }.to raise_error(
            described_class::MissingConfigOptionError, /recipient missing/)
        end

        context 'when it has recipient option' do
          let(:config_data) do
            { 'recipient' => 'recipient@feed2email.org' }
          end

          it 'raises error about sender option missing' do
            expect { subject }.to raise_error(
              described_class::MissingConfigOptionError, /sender missing/)
          end

          context 'when it has sender option' do
            let(:config_data) do
              super().merge('sender' => 'sender@feed2email.org')
            end

            it 'does not raise error' do
              expect { subject }.not_to raise_error
            end

            context 'when send method is invalid' do
              let(:config_data) do
                super().merge('send_method' => 'foo')
              end

              it 'raises error about invalid send_method option' do
                expect { subject }.to raise_error(
                  described_class::InvalidConfigOptionError,
                  /send_method not one of/)
              end
            end

            context 'when send method is smtp' do
              let(:config_data) do
                super().merge('send_method' => 'smtp')
              end

              it 'raises error about missing smtp_host option' do
                expect { subject }.to raise_error(
                  described_class::MissingConfigOptionError,
                  /smtp_host missing/)
              end

              context 'when it has smtp_host option' do
                let(:config_data) do
                  super().merge('smtp_host' => 'smtp.mailgun.org')
                end

                it 'raises error about missing smtp_port option' do
                  expect { subject }.to raise_error(
                    described_class::MissingConfigOptionError,
                    /smtp_port missing/)
                end

                context 'when it has smtp_port option' do
                  let(:config_data) do
                    super().merge('smtp_port' => 587)
                  end

                  it 'raises error about missing smtp_user option' do
                    expect { subject }.to raise_error(
                      described_class::MissingConfigOptionError,
                      /smtp_user missing/)
                  end

                  context 'when it has smtp_user option' do
                    let(:config_data) do
                      super().merge('smtp_user' => 'postmaster@feed2email.org')
                    end

                    it 'raises error about missing smtp_pass option' do
                      expect { subject }.to raise_error(
                        described_class::MissingConfigOptionError,
                        /smtp_pass missing/)
                    end

                    context 'when it has smtp_pass option' do
                      let(:config_data) do
                        super().merge('smtp_pass' => 'password')
                      end

                      it 'does not raise error' do
                        expect { subject }.not_to raise_error
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
