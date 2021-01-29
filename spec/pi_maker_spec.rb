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
      before(:each) { stub_const('RUBY_PLATFORM', platform_strings[:windows]) }

      it { is_expected.to eq(:windows) }
    end

    context 'on mac' do
      before(:each) { stub_const('RUBY_PLATFORM', platform_strings[:mac]) }

      it { is_expected.to eq(:mac) }
    end

    context 'on linux' do
      before(:each) { stub_const('RUBY_PLATFORM', platform_strings[:linux]) }

      it { is_expected.to eq(:linux) }
    end

    context 'on raspberrypi' do
      before(:each) do
        stub_const('RUBY_PLATFORM', platform_strings[:raspberrypi])
        allow(File).to receive(:read).with('/proc/cpuinfo').and_return('Raspberry Pi')
      end

      it { is_expected.to eq(:raspberrypi) }
    end
  end
end
