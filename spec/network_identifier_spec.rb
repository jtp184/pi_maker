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
      let(:program) { PiMaker::NetworkIdentifier::DEFAULT_PROGRAM }

      context 'with a program installed' do
        it 'runs the command' do
          expect { subject }.not_to raise_error
        end

        it { is_expected.to eq(['192.168.1.187']) }
      end
    end

    context 'providing a scan_with program' do
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

      context 'using noninstalled program' do
        let(:program) { :lookit }

        it 'raises an error' do
          expect { subject }.to raise_error(ArgumentError)
        end

        context 'providing procs to use the program' do
          let(:program) { :echo }
          let(:run_with_proc) { ->(i) { i } }
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
end
