RSpec.describe PiMaker::Instructions do
  subject(:instructions) { FactoryBot.build(:instructions) }
  let(:init_args) { FactoryBot.attributes_for(:instructions) }

  it_behaves_like 'block_definable'

  it 'Whitelists attributes' do
    created = described_class.new(init_args.merge(invalid: :argument))

    expect(created.instance_variable_get(:"@invalid")).to be_nil
  end

  it 'can be accessed with []' do
    expect(instructions[:gems]).to include('colorize')
  end

  it 'can convert to a hash' do
    expect(instructions.to_h[:gems]).to include('colorize')
  end
end
