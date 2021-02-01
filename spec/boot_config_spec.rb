RSpec.describe PiMaker::BootConfig do
  let(:boot_config) { described_class.new }

  it 'has default options' do
    expect(described_class.new.to_h.keys.count).not_to be(0)
  end

  define '#to_s' do
    subject { described_class.new.to_s }

    it 'returns a list of config options' do
      expect(subject).to be_a(String)
      expect(subject).to match(/=/)
      expect(subject).to match(/\n/)
    end
  end

  it 'can have options set' do
    boot_config.ssh_enabled = true

    expect(boot_config.to_s).to match(/ssh_enabled=/)
  end
end
