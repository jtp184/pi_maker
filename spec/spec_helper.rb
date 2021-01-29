require 'bundler/setup'

require 'simplecov'
SimpleCov.start

require 'securerandom'
require 'factory_bot'
require 'pry'
require 'pi_maker'

require_relative 'support/matchers'

# Add a patch to pull fixtures in as well
module FactoryBot
  class << self
    def fixtures
      @fixtures ||= Dir.entries('./spec/fixtures')
                       .reject { |f| f =~ /^\./ }
                       .map { |f| [f, File.read("./spec/fixtures/#{f}")] }
                       .to_h
                       .transform_keys(&:to_sym)
    end
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.before(:suite) { FactoryBot.find_definitions }
end
