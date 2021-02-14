RSpec.describe PiMaker::Recipe do
  # subject(:recipe) { FactoryBot.build(:recipe) }

  it_behaves_like 'yaml_exporting' do
    let(:yamlable) { described_class.new }
    # let(:yamlable) { recipe }
  end
end
