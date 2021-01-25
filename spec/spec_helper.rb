require 'bundler/setup'
require 'factory_bot'
require 'pi_maker'
require 'securerandom'
require 'pry'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.before(:suite) { FactoryBot.find_definitions }
end
