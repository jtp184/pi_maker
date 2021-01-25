RSpec.describe PiMaker::Recipe do
  let(:recipe) { FactoryBot.build(:recipe) }
  let(:init_args) { FactoryBot.attributes_for(:recipe) }

  it 'Allows defining by hash' do
    created = described_class.define(init_args)
    expect(created).to be_a(described_class)
  end

  it 'Allows defining by block' do
    created = described_class.define do |recipe|
      init_args.each do |key, value|
        recipe.send(:"#{key}=", value)
      end
    end

    expect(created).to be_a(described_class)
  end

  it 'Whitelists attributes' do
    created = described_class.new(init_args.merge(invalid: :argument))

    expect(created.instance_variable_get(:"@invalid")).to be_nil
  end
end
