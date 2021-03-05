RSpec.describe PiMaker::Recipe do
  subject(:recipe) { FactoryBot.build(:recipe) }

  it_behaves_like 'yaml_exporting' do
    let(:yamlable) { recipe }
  end

  it_behaves_like 'block_definable'

  describe '#login_setup' do
    subject { recipe.login_setup }

    it 'returns instructions to set hostname and password' do
      expect(subject).to be_a(PiMaker::Instructions)
      expect(subject.raspi_config).to have_key(:do_hostname)
      expect(subject.shell.count).to eq(1)
      expect(subject.shell.first).to be_a(String)
      expect(subject.shell.first).to match(/passwd/)
    end
  end
end
