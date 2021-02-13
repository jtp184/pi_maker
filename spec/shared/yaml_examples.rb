RSpec.shared_examples 'yaml_exporting' do
  let(:password) { SecureRandom.hex }

  context 'outputting' do
    context 'without password' do
      subject { yamlable.to_yaml }

      it { is_expected.to be_is_utf8 }

      it 'is valid YAML' do
        expect { Psych.parse(subject) }.not_to raise_error
      end
    end

    context 'with password' do
      subject { yamlable.to_yaml(password) }

      it { is_expected.not_to be_is_utf8 }

      it 'is invalid YAML' do
        expect { Psych.parse(subject) }.to raise_error(Psych::SyntaxError)
      end
    end
  end

  context 'loading' do
    context 'unecrypted' do
      let(:yml_string) { yamlable.to_yaml }

      context 'without password' do
        subject { yamlable.class.from_yaml(yml_string) }

        it 'Creates a valid instance' do
          expect(subject).to be_a(yamlable.class)
        end
      end

      context 'with password' do
        subject { yamlable.class.from_yaml(yml_string, password) }

        it 'ignores the password' do
          expect { subject }.not_to raise_error
          expect(subject).to be_a(yamlable.class)
        end
      end
    end

    context 'encrytped' do
      let(:yml_string) { yamlable.to_yaml(password) }

      context 'with password' do
        subject { yamlable.class.from_yaml(yml_string, password) }

        it 'can decode it' do
          expect(subject).to be_a(yamlable.class)
        end
      end

      context 'without password' do
        subject { yamlable.class.from_yaml(yml_string) }

        it 'raises an error' do
          expect { subject }.to raise_error(PiMaker::PasskeyError)
        end
      end
    end
  end
end
