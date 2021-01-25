RSpec.describe 'Base Module' do
  it 'has a version number' do
    expect(PiMaker::VERSION).not_to be nil
  end

  it 'can detect a host operating system' do
    expect(PiMaker.host_os).to be_a(Symbol)
  end
end
