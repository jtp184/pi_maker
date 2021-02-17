RSpec.describe PiMaker::DiskManagement::FlashingOperation do
  let(:pipe_double) { double('pipe', ready?: true) }
  let(:flashing_operation_attributes) { FactoryBot.attributes_for(:flashing_operation) }
  subject(:flashing_operation) { FactoryBot.build(:flashing_operation) }

  before do
    allow(IO).to receive(:popen).and_return(pipe_double)
  end

  describe '.new' do
    subject { described_class.new(flashing_operation_attributes) }

    it 'takes options for :image_path and :disk' do
      expect(subject).to be_a(described_class)
      expect(subject.image_path).to eq(flashing_operation_attributes[:image_path])
      expect(subject.disk.dev_path).to eq(flashing_operation_attributes[:disk].dev_path)
    end

    it 'does not start a pipe' do
      expect(subject.pipe).to be_nil
    end
  end

  describe '.start' do
    subject { described_class.start(flashing_operation_attributes) }

    it 'returns a FlashingOperation' do
      expect(subject).to be_a(described_class)
    end

    it 'has a running pipe' do
      expect(subject.pipe).not_to be_nil
    end
  end

  describe '#call' do
    it 'starts the pipe' do
      expect { flashing_operation.call }.to(change { flashing_operation.pipe })
    end
  end

  describe '#finished?' do
    subject { flashing_operation.finished? }

    context 'when pipe is ready to read' do
      before { flashing_operation.call }

      it { is_expected.to be(true) }
    end

    context 'when pipe is not ready to read' do
      let(:pipe_double) { double('pipe', ready?: false) }

      before { flashing_operation.call }

      it { is_expected.to be(false) }
    end

    context 'when pipe is nonexistent' do
      let(:pipe_double) { nil }

      it { is_expected.to be(nil) }
    end
  end
end
