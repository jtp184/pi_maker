# frozen_string_literal: true

require 'thor'

module PiMaker
  # Handle the application command line parsing
  # and the dispatch to various command objects
  #
  # @api public
  class CLI < Thor
    # Error raised by this runner
    Error = Class.new(StandardError)

    # Returns proper exit code
    def self.exit_on_failure?
      true
    end

    class_option :interactive, aliases: '-i', type: :boolean, default: false,
                               desc: 'Run with prompting'
    class_option :help, aliases: '-h', type: :boolean, desc: 'Display usage information'

    desc 'version', 'pi_maker version'
    # Return version number
    def version
      require_relative 'version'
      puts "v#{PiMaker::VERSION}"
    end
    map %w[--version -v] => :version

    desc 'identify', 'Find Raspberry Pi devices on the local network'

    method_option :range, aliases: '-r', default: '192.168.1.0/24', desc: 'Which ip range to target'
    method_option :program, aliases: '-p', default: PiMaker::NetworkIdentifier::DEFAULT_PROGRAM[PiMaker.host_os],
                            desc: 'What program to run with'
    method_option :output, aliases: '-o', default: 'i',
                           desc: 'What data to return, either [i]p, [h]ostname, or [b]oth'
    # Identify pis on the network
    def identify(*)
      if options[:help]
        invoke :help, ['identify']
      else
        require_relative 'commands/identify'
        PiMaker::Commands::Identify.new(options).execute
      end
    end

    require_relative 'commands/boot'
    register PiMaker::Commands::Boot, 'boot', 'boot [SUBCOMMAND]',
             'Flash an SD card, or directly write to a config file'

    require_relative 'commands/wifi'
    register PiMaker::Commands::Wifi, 'wifi', 'wifi [SUBCOMMAND]',
             'Store and use wifi network credentials'

    require_relative 'commands/recipe'
    register PiMaker::Commands::Recipe, 'recipe', 'recipe [SUBCOMMAND]',
             'Create and use recipes'

    require_relative 'commands/pantry'
    register PiMaker::Commands::Pantry, 'pantry', 'pantry [SUBCOMMAND]',
             'Handle data in the persistant store'

    require_relative 'commands/remote'
    register PiMaker::Commands::Remote, 'remote', 'remote [SUBCOMMAND]',
             'Control the pi remotely'
  end
end
