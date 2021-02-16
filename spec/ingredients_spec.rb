RSpec.describe PiMaker::Ingredients do
  subject(:ingredients) { FactoryBot.build(:ingredients) }
  let(:init_args) { FactoryBot.attributes_for(:ingredients) }

  it_behaves_like 'block_definable'

  it 'Whitelists attributes' do
    created = described_class.new(init_args.merge(invalid: :argument))

    expect(created.instance_variable_get(:"@invalid")).to be_nil
  end

  it 'can be accessed with []' do
    expect(ingredients[:gems]).to include('colorize')
  end

  it 'can convert to a hash' do
    expect(ingredients.to_h[:gems]).to include('colorize')
  end
end
