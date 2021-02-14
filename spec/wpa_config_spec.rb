RSpec.describe PiMaker::WpaConfig do
  WPA_CONFIG_VALIDATOR = %r{
    ctrl_interface=DIR=/var/run/wpa_supplicant\sGROUP=netdev\n
    update_config=1\n
    country=\w{2}\n\n
    network=\{
  }x.freeze

  subject(:wpa_config) { FactoryBot.build(:wpa_config) }
  let(:network) { { 'WifiNetwork' => 'WifiPassword' } }

  it_behaves_like 'yaml_exporting' do
    let(:yamlable) { wpa_config }
  end

  describe '#append' do
    subject { wpa_config.append('NetworkAppended', 'PasswordAppended') }

    it 'adds a new network to the collection' do
      expect { subject }.to change { wpa_config.networks.count }.by(1)
      expect(wpa_config.ssid?('NetworkAppended')).to be(true)
    end

    it 'returns the wpa_config' do
      expect(subject).to be(wpa_config)
    end
  end

  describe '#ssid?' do
    it 'returns true if the wpa_config contains the SSID' do
      expect(subject.ssid?(subject.networks.keys.first)).to be(true)
    end
  end

  describe '#to_s' do
    it 'returns a valid wpa config file' do
      expect(subject.to_s).to match(WPA_CONFIG_VALIDATOR)
    end
  end
end
