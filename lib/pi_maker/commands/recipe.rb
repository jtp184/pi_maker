# frozen_string_literal: true

require 'thor'

module PiMaker
  module Commands
    class Recipe < Thor
      namespace :recipe

      desc 'delete [HOSTNAME]', 'Remove a recipe'

      def delete(hostname = nil)
        if options[:help]
          invoke :help, ['delete']
        else
          require_relative 'recipe/delete'
          PiMaker::Commands::Recipe::Delete.new(hostname, options).execute
        end
      end

      desc 'list', 'Show all recipes from a certain collection'

      def list(*)
        if options[:help]
          invoke :help, ['list']
        else
          require_relative 'recipe/list'
          PiMaker::Commands::Recipe::List.new(options).execute
        end
      end

      desc 'gem [GEMNAME]', 'Create a recipe with a gem as a starting point'

      method_option :hostname, aliases: '-n', type: :string,
                               desc: 'Set the hostname'

      method_option :password, aliases: '-w', type: :string,
                               desc: 'Set the password'

      method_option :wifi_options, aliases: '-f', type: :hash,
                                   desc: 'Set the wifi options'

      method_option :boot_options, aliases: '-b', type: :hash,
                                   desc: 'Set the boot options'

      method_option :pantry, aliases: '-p', type: :boolean, default: true,
                             desc: 'Save this recipe to the pantry as well'

      method_option :local_file, aliases: '-l', type: :boolean, default: false,
                                 desc: 'Whether to write out a local file with the contents'

      def gem(gemname = nil)
        if options[:help]
          invoke :help, ['gem']
        else
          require_relative 'recipe/gem'
          PiMaker::Commands::Recipe::Gem.new(gemname, options).execute
        end
      end

      desc 'add', 'Add a new recipe'

      method_option :hostname, aliases: '-n', type: :string,
                               desc: 'Set the hostname'

      method_option :password, aliases: '-w', type: :string,
                               desc: 'Set the password'

      method_option :wifi_options, aliases: '-f', type: :hash,
                                   desc: 'Set the wifi options'

      method_option :boot_options, aliases: '-b', type: :hash,
                                   desc: 'Set the boot options'

      method_option :initial_setup, aliases: '-o', type: :hash,
                                    desc: 'Set the initial setup options'

      method_option :export_format, aliases: '-e', type: :string, default: 'yaml',
                                    desc: 'Output as ruby or yaml'

      method_option :pantry, aliases: '-p', type: :boolean, default: true,
                             desc: 'Save this recipe to the pantry as well'

      method_option :local_file, aliases: '-l', type: :boolean, default: false,
                                 desc: 'Whether to write out a local file with the contents'

      method_option :ssh, aliases: '-s', type: :boolean, default: true,
                          desc: 'Enable ssh on boot'

      def add(*)
        if options[:help]
          invoke :help, ['add']
        else
          require_relative 'recipe/add'
          PiMaker::Commands::Recipe::Add.new(options).execute
        end
      end

      desc 'write_boot', "Write a recipe's boot config to the SD card"

      method_option :path, aliases: '-p', type: :string,
                           desc: 'Save to a specific path'

      def write_boot(hostname = nil)
        if options[:help]
          invoke :help, ['write_boot']
        else
          require_relative 'recipe/write_boot'
          PiMaker::Commands::Recipe::WriteBoot.new(hostname, options).execute
        end
      end

      desc 'initial', 'Perform the initial setup commands from the recipe'

      method_option :path, aliases: '-p', type: :string,
                           desc: 'Save to a specific path'

      method_option :verbose, aliases: '-v', type: :boolean,
                              desc: 'Whether to print command output'

      method_option :reboot, aliases: '-r', type: :boolean,
                             desc: 'Reboot after running commands'

      method_option :login, aliases: '-l', type: :boolean, default: true,
                            desc: 'Set the hostname and password'

      method_option :credentials, aliases: '-c', type: :hash,
                                  desc: 'Pass in login details directly'

      method_option :scan, aliases: '-s', type: :boolean, default: true,
                           desc: 'Use the network identifier to pick a pi'

      method_option :scan_with, aliases: '-w', type: :string,
                                desc: 'Use a different program to scan with'

      def initial(hostname = nil)
        if options[:help]
          invoke :help, ['initial']
        else
          require_relative 'recipe/initial'
          PiMaker::Commands::Recipe::Initial.new(hostname, options).execute
        end
      end
    end
  end
end
