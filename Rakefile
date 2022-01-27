require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RDOC_EXCLUDE = %w[
  bin/console
  bin/setup
  coverage
  docs
  Gemfile
  Gemfile.lock
  lib/pi_maker/commands
  pkg
  Rakefile
  spec
  tmp
  wpa_supplicant.conf
].map { |r| "--exclude=#{r}" }.join(' ').freeze

RSpec::Core::RakeTask.new(:spec)

RSpec::Core::RakeTask.new(:quick_spec) do |r|
  r.rspec_opts = '-fp --fail-fast'
end

task default: :quick_spec

task :docs do
  sh "rdoc --output=docs --format=hanna --all --main=README.md #{RDOC_EXCLUDE}"
end

task :docs do
  sh "rdoc --output=docs --format=hanna --all --main=README.md #{RDOC_EXCLUDE}"
end

task :reinstall do
  needs_sudo = Gem.platforms.last.os == 'linux'
  sh "#{needs_sudo ? 'sudo ' : ''}gem uninstall pi_maker"
  sh "#{needs_sudo ? 'sudo ' : ''}rake install"
end
