RSpec.describe PiMaker::CommandGroup do
  subject(:command_group) { FactoryBot.build(:command_group) }

  describe '#commands' do
    subject { command_group.commands }

    it 'returns a string array' do
      expect(subject).to be_a(Array)
      expect(subject).to all(be_a(String))
    end
  end

  describe '#text_blocks' do
    subject { command_group.text_blocks }

    it 'returns a filepath => string array hash' do
      expect(subject).to be_a(Hash)

      expect(subject.keys).to all(be_a(String))
      expect(subject.keys).to all(be_a_filepath)

      expect(subject.values).to all(be_a(Array))
      expect(subject.values).to all(all(be_a(String)))
    end
  end

  describe 'transformation methods' do
    it 'responds to all of the Instructions fields' do
      mtds = PiMaker::Instructions::LISTS.keys + PiMaker::Instructions::TEXT_BLOCKS.keys

      mtds.each do |mtd|
        expect(command_group).to respond_to(mtd)
      end
    end
  end
end
