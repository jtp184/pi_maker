RSpec.describe PiMaker::NetworkIdentifier do
  before(:each) do
    allow(PiMaker::NetworkIdentifier).to receive(:run_nmap) { FactoryBot.fixtures[:nmap] }
  end

  describe '.call' do
    it 'returns a list of ips' do
      expect(described_class.call).to all(be_a(String))
    end

    it 'ignores non-pi hosts' do
      expect(described_class.call).to eq(['192.168.1.187'])
    end
  end
end
