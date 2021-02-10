RSpec.describe PiMaker::DiskManagement do
  it 'can respond to disk methods defined below it' do
    expect(described_class).to respond_to(:list_devices)
  end

  describe '.protocol' do
    subject { described_class.protocol }

    context 'on linux' do
      include_context 'on linux platform'

      it { is_expected.to be(PiMaker::DiskManagement::Linux) }
    end

    context 'on mac' do
      include_context 'on mac platform'

      it { is_expected.to be(PiMaker::DiskManagement::MacOs) }
    end
  end
end
