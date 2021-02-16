RSpec.describe PiMaker::Recipe do
  subject(:recipe) { FactoryBot.build(:recipe) }

  it_behaves_like 'yaml_exporting' do
    let(:yamlable) { recipe }
  end

  it_behaves_like 'block_definable'
end
