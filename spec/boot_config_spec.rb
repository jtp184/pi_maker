RSpec.describe PiMaker::BootConfig do
  let(:boot_config) { described_class.new }

  it 'has default options' do
    expect(described_class.new.to_h.keys.count).not_to be(0)
  end

  it 'can have options set' do
    boot_config.all.ssh_enabled = true
    expect(boot_config.to_s).to match(/ssh_enabled=/)
  end

  define 'default path by OS' do
    subject { described_class.new.path }

    context 'on mac' do
      before { allow(PiMaker).to receive(:host_os).and_return(:mac) }

      it { is_expected.to eq('/Volumes/boot/config.txt') }
    end

    context 'on linux' do
      before { allow(PiMaker).to receive(:host_os).and_return(:linux) }

      it { is_expected.to eq('/mnt/boot/config.txt') }
    end

    context 'on windows' do
      before { allow(PiMaker).to receive(:host_os).and_return(:windows) }

      it { is_expected.to eq('E:/config.txt') }
    end
  end

  define '#to_s' do
    subject { described_class.new.to_s }

    it 'returns a list of config options' do
      expect(subject).to be_a(String)
      expect(subject).to match(/=/)
      expect(subject).to match(/\n/)
    end
  end

  define '#[]' do
    let(:config_params) do
      {
        'pi3' => { 'test_3_param' => true },
        'all' => { 'test_all_param' => 1 }
      }
    end

    let(:boot_config) { FactoryBot.new(:boot_config, config: config_params) }

    context 'key is one of the filters' do
      subject { boot_config['pi3'] }

      it { is_expected.to be_a(Hash) }
    end

    context 'key is not one of the filters' do
      subject { boot_config['test_all_param'] }

      it { is_expected.to be_a(Integer) }
    end
  end
end
