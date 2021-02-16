RSpec.describe PiMaker::Pantry do
  subject(:pantry) { FactoryBot.build(:pantry, base_path: @temp_path) }
  let(:secure_pantry) { FactoryBot.build(:pantry, password: SecureRandom.hex, base_path: @temp_path) }

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

  describe 'in memory with data' do
    it 'can retain recipes and networks' do
      expect(subject.wifi_networks).to be_a(Hash)
      expect(subject.recipes).to be_a(Array)
      expect(subject.recipes).not_to be_empty
    end
  end

  describe 'with password' do
    subject { secure_pantry }

    it 'has a password attribute' do
      expect(subject.password).not_to be_nil
    end
  end

  describe 'loading from path' do
    before do
      subject.write(path: @temp_path)
      subject.clear.reload
    end

    describe 'unsecure' do
      it 'can read recipes from the folder' do
        expect(subject.recipes).to be_a(Array)
        expect(subject.recipes).not_to be_empty
        expect(subject.recipes).to all(be_a(PiMaker::Recipe))
      end
    end

    describe 'secure' do
      subject { secure_pantry }

      it 'can read recipes from the folder' do
        expect(subject.recipes).to be_a(Array)
        expect(subject.recipes).not_to be_empty
        expect(subject.recipes).to all(be_a(PiMaker::Recipe))
      end
    end
  end

  describe 'writing to path' do
    before { subject.write(path: @temp_path) }
    let(:wifi_config_path) { @temp_path + '/wifi_config.yml' }
    let(:recipe_path) do
      Dir[@temp_path + '/recipes/*'].detect { |e| e.match?(/\.yml$/) }
    end

    describe 'unsecure' do
      it 'writes valid YAML' do
        expect { Psych.parse(File.read(wifi_config_path)) }.not_to raise_error
        expect { Psych.parse(File.read(recipe_path)) }.not_to raise_error
      end
    end

    describe 'secure' do
      subject { secure_pantry }
      let(:wifi_config_path) { @temp_path + '/wifi_config.enc.yml' }
      let(:recipe_path) do
        Dir[@temp_path + '/recipes/*'].detect { |e| e.match?(/\.enc\.yml$/) }
      end

      xit 'writes invalid YAML' do
        expect { Psych.parse(File.read(wifi_config_path)) }.to raise_error
        expect { Psych.parse(File.read(recipe_path)) }.not_to raise_error
      end
    end
  end
end
