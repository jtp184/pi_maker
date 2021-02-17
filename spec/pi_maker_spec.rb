RSpec.describe 'Base Module' do
  it 'has a version number' do
    expect(PiMaker::VERSION).not_to be nil
  end

  describe '.host_os' do
    let(:platform_strings) do
      {
        windows: 'mswin',
        mac: 'darwin',
        linux: 'linux',
        raspberrypi: 'linux'
      }
    end

    subject { PiMaker.host_os }

    context 'on windows' do
      include_context 'on windows platform'

      it { is_expected.to eq(:windows) }
    end

    context 'on mac' do
      include_context 'on mac platform'

      it { is_expected.to eq(:mac) }
    end

    context 'on linux' do
      include_context 'on linux platform'

      it { is_expected.to eq(:linux) }
    end

    context 'on raspberrypi' do
      include_context 'on raspberrypi platform'

      it { is_expected.to eq(:raspberrypi) }
    end
  end

  describe '.sd_card_path' do
    subject { PiMaker.sd_card_path }

    context 'on mac' do
      before { allow(PiMaker).to receive(:host_os).and_return(:mac) }

      it { is_expected.to eq('/Volumes/boot') }
    end

    context 'on linux' do
      before { allow(PiMaker).to receive(:host_os).and_return(:linux) }

      it { is_expected.to eq('/mnt/boot') }
    end

    context 'on windows' do
      before { allow(PiMaker).to receive(:host_os).and_return(:windows) }

      it { is_expected.to eq('E:') }
    end
  end

  describe '.system_cmd' do
    let(:cmd_opts) { 'echo hello' }
    let(:cmd_result) { TTY::Command::Result.new(0, '', '') }

    subject { PiMaker.system_cmd(cmd_opts) }

    before do
      allow_any_instance_of(TTY::Command).to receive(:run!).and_return(cmd_result)
    end

    context 'on success' do
      let(:cmd_result) { TTY::Command::Result.new(0, '', '') }

      it 'can execute commands' do
        expect { subject }.not_to raise_error
      end
    end

    context 'on failure' do
      let(:cmd_result) { TTY::Command::Result.new(1, '', '') }

      it 'raises an error' do
        expect { subject }.to raise_error(PiMaker::SystemCommandError)
      end
    end

    context 'with complex arguments' do
      let(:cmd_opts) { { command: ['ls', '-la'] } }

      it 'can execute commands' do
        expect { subject }.not_to raise_error
      end
    end

    context 'with :raise_errors set to false' do
      let(:cmd_opts) { { command: 'echo hello', raise_errors: false } }

      context 'on success' do
        let(:cmd_result) { TTY::Command::Result.new(0, '', '') }

        it 'can execute commands' do
          expect { subject }.not_to raise_error
        end
      end

      context 'on failure' do
        let(:cmd_result) { TTY::Command::Result.new(1, '', '') }

        it 'does not raise an error' do
          expect { subject }.not_to raise_error
        end
      end
    end
  end
end
