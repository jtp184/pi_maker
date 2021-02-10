RSpec.shared_context 'on windows platform' do
  before(:each) { stub_const('RUBY_PLATFORM', 'mswin') }
end

RSpec.shared_context 'on mac platform' do
  before(:each) { stub_const('RUBY_PLATFORM', 'darwin') }
end

RSpec.shared_context 'on linux platform' do
  before(:each) do
    stub_const('RUBY_PLATFORM', 'linux')
    allow(File).to receive(:read).with('/proc/cpuinfo').and_return('Ubuntu')
  end
end

RSpec.shared_context 'on raspberrypi platform' do
  before(:each) do
    stub_const('RUBY_PLATFORM', 'linux')
    allow(File).to receive(:read).with('/proc/cpuinfo').and_return('Raspberry Pi')
  end
end
