require 'spec_helper'

describe Feed2Email do
  let(:config_dir) { 'spec/fixtures/.feed2email' }

  before do
    stub_const('Feed2Email::CONFIG_DIR', config_dir)
  end

  it 'has a CONFIG_DIR constant' do
    expect { Feed2Email::CONFIG_DIR }.not_to raise_error
    expect(Feed2Email::CONFIG_DIR).to eql config_dir
  end

  describe 'Config' do
    subject { Feed2Email::Config.instance }

    let(:config_file) { File.join(config_dir, 'config.yml') }

    before do
      stub_const('Feed2Email::Config::CONFIG_FILE', config_file)
    end

    it 'is a singleton' do
      expect { Feed2Email::Config.new }.to raise_error
      expect(Feed2Email::Config).to respond_to :instance
      expect(subject).to eql Feed2Email::Config.instance
    end

    it 'has a CONFIG_FILE constant' do
      expect { Feed2Email::Config::CONFIG_FILE }.not_to raise_error
      expect(Feed2Email::Config::CONFIG_FILE).to eql config_file
    end

    describe '#config' do
      let(:config_data) { 'foobar' }

      before do
        subject.instance_variable_set(:@config, config_data)
      end

      it 'is an attr_reader' do
        expect(subject.config).to eql config_data
      end
    end

    describe '#read!' do
      before do
        FileUtils.mkdir_p(config_dir)
      end

      context 'config file is missing' do
        before do
          FileUtils.rm_f(config_file)

          STDERR.should_receive(:puts).with(/missing .*config file/)
        end

        it 'exits with an error' do
          exit_status = nil

          expect {
            begin
              subject.read!
            rescue SystemExit => e
              exit_status = e.status
            end
          }.to change {
            exit_status
          }.from(nil).to(1)
        end
      end

      context 'config file is invalid' do
        before do
          FileUtils.rm_f(config_file)
          FileUtils.touch(config_file) # empty file

          STDERR.should_receive(:puts).with(/invalid .*config file/)
        end

        it 'exits with an error' do
          exit_status = nil

          expect {
            begin
              subject.read!
            rescue SystemExit => e
              exit_status = e.status
            end
          }.to change {
            exit_status
          }.from(nil).to(1)
        end
      end

      context 'config file is valid' do
        before do
          open(config_file, 'w') {|f| f.write('{}') }
        end

        context 'has invalid permissions' do
          before do
            File.chmod(0644, config_file) # world-readable

            STDERR.should_receive(:puts).with(/invalid permissions/)
          end

          it 'exits with an error' do
            exit_status = nil

            expect {
              begin
                subject.read!
              rescue SystemExit => e
                exit_status = e.status
              end
            }.to change {
              exit_status
            }.from(nil).to(2)
          end
        end

        context 'has valid permissions' do
          before do
            File.chmod(0600, config_file) # private
          end

          context 'has no recipient address' do
            before do
              open(config_file, 'w') {|f| f.write('{}') }

              STDERR.should_receive(:puts).with(/recipient missing/)
            end

            it 'exits with an error' do
              exit_status = nil

              expect {
                begin
                  subject.read!
                rescue SystemExit => e
                  exit_status = e.status
                end
              }.to change {
                exit_status
              }.from(nil).to(3)
            end
          end

          context 'has recipient address' do
            let(:recipient) { 'foo@bar.com' }

            before do
              open(config_file, 'w') {|f| f.write("recipient: #{recipient}") }
            end

            it 'assigns config data to instance variable' do
              expect {
                subject.read!
              }.to change {
                subject.instance_variable_get(:@config)
              }.from(nil).to('recipient' => recipient)
            end

            it 'does not exit with an error' do
              expect(subject.read!).to be_nil
            end
          end
        end
      end

      after do
        subject.instance_variable_set(:@config, nil)
        FileUtils.rm_rf(config_dir)
      end
    end
  end
end
