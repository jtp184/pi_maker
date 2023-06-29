require_relative 'lib/pi_maker/version'

Gem::Specification.new do |spec|
  spec.name          = 'pi_maker'
  spec.license       = 'MIT'
  spec.version       = PiMaker::VERSION
  spec.authors       = ['Justin Piotroski']
  spec.email         = ['justin.piotroski@gmail.com']

  spec.summary       = 'Easy bake Raspberry Pi'
  spec.description   = 'Easily create and configure Raspberry Pis, and tightly integrate ruby gems!'
  spec.homepage      = 'https://github.com/jtp184/pi_maker'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  spec.metadata['homepage_uri'] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'factory_bot', '~> 6.1.0'
  spec.add_development_dependency 'pry', '~> 0.13.1'
  spec.add_development_dependency 'rubocop', '~> 0.9.0'
  spec.add_development_dependency 'simplecov', '~> 0.19.0'
  spec.add_development_dependency 'strings-case', '~> 0.3.0'

  spec.add_runtime_dependency 'activesupport', '~> 6.1'
  spec.add_runtime_dependency 'net-scp', '~> 3.0.0'
  spec.add_runtime_dependency 'net-ssh', '~> 6.1.0'
  spec.add_runtime_dependency 'pastel', '~> 0.8.0'
  spec.add_runtime_dependency 'plist', '~> 3.6.0'
  spec.add_runtime_dependency 'strings-case', '~> 0.3.0'
  spec.add_runtime_dependency 'tty-box', '~> 0.7.0'
  spec.add_runtime_dependency 'tty-command', '~> 0.10.1'
  spec.add_runtime_dependency 'tty-config', '~> 0.4.0'
  spec.add_runtime_dependency 'tty-editor', '~> 0.6.0'
  spec.add_runtime_dependency 'tty-exit', '~> 0.1.0'
  spec.add_runtime_dependency 'tty-file', '~> 0.10.0'
  spec.add_runtime_dependency 'tty-logger', '~> 0.6.0'
  spec.add_runtime_dependency 'tty-pager', '~> 0.14.0'
  spec.add_runtime_dependency 'tty-progressbar', '~> 0.18.0'
  spec.add_runtime_dependency 'tty-prompt', '~> 0.23.0'
  spec.add_runtime_dependency 'tty-spinner', '~> 0.9.3'
  spec.add_runtime_dependency 'tty-which', '~> 0.4.2'
end
