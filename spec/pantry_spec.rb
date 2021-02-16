RSpec.describe PiMaker::Pantry do
  subject(:pantry) { FactoryBot.build(:pantry, base_path: @temp_path) }
  let(:secure_pantry) { FactoryBot.build(:secure_pantry, base_path: @temp_path) }

  before :all do
    @temp_dir = Dir.mktmpdir("pi_maker_pantry_test_#{SecureRandom.uuid}")
  end

  before :each do
    ident = Time.now.to_i
    FileUtils.mkdir_p(@temp_dir + "/#{ident}/recipes")
    @temp_path = @temp_dir + "/#{ident}"
  end

  after(:each) { FileUtils.rm_rf(@temp_path) }
  after(:all) { FileUtils.rm_rf(@temp_dir) }

  it 'can retain recipes and networks' do
    expect(subject.wifi_networks).to be_a(Hash)
    expect(subject.recipes).to be_a(Array)
  end

  describe 'unsecure' do
  end

  describe 'secure' do
  end
end
