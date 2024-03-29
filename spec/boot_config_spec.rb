RSpec.describe PiMaker::BootConfig do
  subject(:boot_config) { FactoryBot.build(:boot_config) }
  let(:test_value) { { 'testkey=testval' => 1 } }

  it_behaves_like 'yaml_exporting' do
    let(:yamlable) { boot_config }
  end

  it 'has default options' do
    expect(described_class.new.to_h.keys.count).not_to be(0)
  end

  it 'can have options set' do
    boot_config.all.ssh_enabled = true
    expect(boot_config.to_s).to match(/ssh_enabled=/)
  end

  it 'can have options set directly and put them in \'all\'' do
    boot_config.testexample = true
    expect(boot_config.all.testexample).to eq(true)
  end

  it 'can write a filter config directly' do
    boot_config.pi0 = test_value
    expect(boot_config.pi0).to be_a(OpenStruct)
  end

  it 'can instantiate a filter config' do
    fc = described_class.new(config: { pi0: test_value })

    expect(fc.pi0).to be_a(OpenStruct)
    expect(fc['pi0']['testkey=testval']).to eq(1)
  end

  it 'can instantiate a general config' do
    fc = described_class.new(config: test_value)

    expect(fc['all']['testkey=testval']).to eq(1)
  end

  it 'responds to filters' do
    expect(boot_config).to respond_to(:pi3)
  end

  describe 'reading files when path is passed' do
    before do
      allow(File).to receive(:read).and_return(
        "[pi4]\ndtparam=audio=on\nmax_framebuffers=2\n[all]\ndtoverlay=vc4-fkms-v3d\ntest_option=0\n\n"
      )

      allow(File).to receive(:exist?).and_return(true)
    end

    it 'reads the file' do
      expect(described_class.new(path: '/path/to/file').test_option).to eq('0')
    end
  end

  describe '#to_s' do
    subject { described_class.new.to_s }

    it 'returns a list of config options' do
      expect(subject).to be_a(String)
      expect(subject).to match(/=/)
      expect(subject).to match(/\n/)
    end
  end

  describe 'hash accessors' do
    let(:config_params) do
      {
        'pi3' => { 'test_3_param' => true },
        'all' => { 'test_all_param' => 1 }
      }
    end

    let(:boot_config) { FactoryBot.build(:boot_config, config: config_params) }

    describe '#[]' do
      context 'key is one of the filters' do
        subject { boot_config['pi3'] }

        it { is_expected.to be_a(OpenStruct) }
      end

      context 'key is not one of the filters' do
        subject { boot_config['test_all_param'] }

        it { is_expected.to be_a(Integer) }
      end
    end

    describe '#[]=' do
      context 'when given a defined filter' do
        it 'applies the key to that filter' do
          expect { boot_config['pi3'] = OpenStruct.new }.to change {
            boot_config.pi3.test_3_param
          }.from(true).to(nil)
        end
      end

      context 'when not passed a defined filter' do
        it 'applies the key to all configs' do
          expect { boot_config['test_heql_param'] = true }.to change {
            boot_config['all']['test_heql_param']
          }.from(nil).to(true)
        end
      end
    end
  end
end
