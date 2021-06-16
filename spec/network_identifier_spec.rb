RSpec.describe PiMaker::NetworkIdentifier do
  describe '.call' do
    subject { described_class.call }

    before do
      allow(TTY::Which).to(
        receive(:which).with(program.to_s).and_return(!FactoryBot.fixtures[program].nil?)
      )

      allow(PiMaker).to receive(:system_cmd).and_return(FactoryBot.fixtures[program])
    end

    context 'with no provided scan_with program' do
      let(:program) { PiMaker::NetworkIdentifier::DEFAULT_PROGRAM[PiMaker.host_os] }

      context 'with a program installed' do
        it 'runs the command' do
          expect { subject }.not_to raise_error
        end

        it 'ignores non-pi hosts' do
          expect(subject.map(&:ip_address)).to eq(['192.168.1.187'])
        end
      end
    end

    context 'providing a scan_with program' do
      subject { described_class.call(scan_with: program) }

      context 'using nmap' do
        let(:program) { :nmap }

        it 'returns a list of results' do
          expect(subject).to all(be_a(PiMaker::NetworkIdentifier::ScanResult))
        end

        it 'ignores non-pi hosts' do
          expect(subject.map(&:ip_address)).to eq(['192.168.1.187'])
        end
      end

      context 'using arp' do
        let(:program) { :arp }

        it 'returns a list of results' do
          expect(subject).to all(be_a(PiMaker::NetworkIdentifier::ScanResult))
        end

        it 'ignores non-pi hosts' do
          expect(subject.map(&:ip_address)).to eq(['192.168.1.187'])
        end
      end

      context 'using noninstalled program' do
        let(:program) { :lookit }

        it 'raises an error' do
          expect { subject }.to raise_error(ArgumentError)
        end

        context 'providing procs to use the program' do
          let(:program) { :echo }
          let(:run_with_proc) { -> {} }
          let(:parse_with_proc) { ->(i) { i } }
          let(:filter_with_proc) { ->(i) { i } }

          subject do
            described_class.call(
              scan_with: program,
              run_with: run_with_proc,
              filter_with: filter_with_proc,
              parse_with: parse_with_proc
            )
          end

          it 'uses the procs to run the program' do
            expect { subject }.not_to raise_error
          end
        end
      end
    end
  end

  describe 'ScanResult' do
    before do
      allow(TTY::Which).to(
        receive(:which).with(program.to_s).and_return(!FactoryBot.fixtures[program].nil?)
      )

      allow(PiMaker).to receive(:system_cmd).and_return(FactoryBot.fixtures[program])
    end

    let(:program) { :nmap }
    subject { described_class.call(scan_with: :nmap).first }

    describe 'to_s' do
      it 'returns the ip_address' do
        expect(subject.to_s).to eq(subject.ip_address)
        expect(subject.to_str).to eq(subject.ip_address)
      end
    end
  end

  describe '::DEFAULT_PROGRAM' do
    context 'on mac' do
      it 'returns :arp' do
        expect(described_class::DEFAULT_PROGRAM[:mac]).to eq(:arp)
      end
    end

    context 'on linux' do
      it 'returns :nmap' do
        expect(described_class::DEFAULT_PROGRAM[:linux]).to eq(:nmap)
      end
    end
  end
end
