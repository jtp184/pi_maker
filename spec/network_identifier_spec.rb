RSpec.describe PiMaker::NetworkIdentifier do
  describe '.call' do
    subject { described_class.call(scan_with: program) }

    before do
      allow(TTY::Which).to(
        receive(:which).with(program.to_s).and_return(!FactoryBot.fixtures[program].nil?)
      )
    end

    context 'using nmap' do
      let(:program) { :nmap }
      before { allow(PiMaker).to receive(:system_cmd).and_return(FactoryBot.fixtures[:nmap]) }

      it 'returns a list of ips' do
        expect(subject).to all(be_a(String))
      end

      it 'ignores non-pi hosts' do
        expect(subject).to eq(['192.168.1.187'])
      end
    end

    context 'using arp' do
      let(:program) { :arp }
      before { allow(PiMaker).to receive(:system_cmd).and_return(FactoryBot.fixtures[:arp]) }

      it 'returns a list of ips' do
        expect(subject).to all(be_a(String))
      end

      it 'ignores non-pi hosts' do
        expect(subject).to eq(['192.168.1.187'])
      end
    end
  end
end
