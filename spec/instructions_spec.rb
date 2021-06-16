RSpec.describe PiMaker::Instructions do
  subject(:instructions) { FactoryBot.build(:instructions) }
  let(:init_args) { FactoryBot.attributes_for(:instructions) }
  let(:other_instruction) { described_class.new(shell: ['rbenv rehash']) }

  it_behaves_like 'block_definable'

  it 'Whitelists attributes' do
    created = described_class.new(init_args.merge(invalid: :argument))

    expect(created.instance_variable_get(:@invalid)).to be_nil
  end

  it 'can be accessed with []' do
    expect(instructions[:gems]).to include('colorize')
  end

  it 'can convert to a hash' do
    expect(instructions.to_h[:gems]).to include('colorize')
  end

  it 'can be concatenated with +' do
    new_ins = subject + other_instruction

    expect(new_ins).to be_a(described_class)
    expect(new_ins[:shell]).to include('rbenv rehash')
    expect(new_ins[:gems]).to include('colorize')
  end
end
