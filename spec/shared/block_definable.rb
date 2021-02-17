RSpec.shared_examples 'block_definable' do
  let(:block_definable_init_args) do
    cname = Strings::Case.underscore(described_class.name.split('::').last).to_sym
    FactoryBot.attributes_for(cname)
  end

  it 'Allows defining by hash' do
    created = described_class.define(block_definable_init_args)

    expect(created).to be_a(described_class)
  end

  it 'Allows defining by block' do
    created = described_class.define do |ig|
      block_definable_init_args.each do |key, value|
        ig.send(:"#{key}=", value)
      end
    end

    expect(created).to be_a(described_class)
  end
end
