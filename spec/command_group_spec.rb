RSpec.describe PiMaker::CommandGroup do
  let(:command_group) { FactoryBot.build(:command_group) }

  describe 'commands' do
    subject { command_group.commands }

    it 'returns a string array' do
      expect(subject).to be_a(Array)
      expect(subject).to all(be_a(String))
    end
  end
end
