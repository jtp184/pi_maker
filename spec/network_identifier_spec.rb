RSpec.describe PiMaker::NetworkIdentifier do
  before(:each) do
    allow(PiMaker::NetworkIdentifier).to receive(:run_nmap) { FactoryBot.fixtures[:nmap] }
    allow(PiMaker::NetworkIdentifier).to receive(:run_arp) { FactoryBot.fixtures[:arp] }
  end

  describe '.call' do
    subject { described_class.call(scan_with: program) }

    context 'using nmap' do
      let(:program) { :nmap }

      it 'returns a list of ips' do
        expect(subject).to all(be_a(String))
      end

      it 'ignores non-pi hosts' do
        expect(subject).to eq(['192.168.1.187'])
      end
    end

    context 'using arp' do
      let(:program) { :arp }

      it 'returns a list of ips' do
        expect(subject).to all(be_a(String))
      end

      it 'ignores non-pi hosts' do
        expect(subject).to eq(['192.168.1.187'])
      end
    end
  end
end
