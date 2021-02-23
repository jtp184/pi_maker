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

      desc 'add', 'Add a new recipe'

      method_option :hostname, aliases: '-n', type: :string,
                               desc: 'Set the hostname'

      method_option :password, aliases: '-w', type: :string,
                               desc: 'Set the password'

      method_option :wifi_options, aliases: '-f', type: :hash,
                                   desc: 'Set the wifi options'

      method_option :boot_options, aliases: '-b', type: :hash,
                                   desc: 'Set the boot options'

      method_option :initial_options, aliases: '-o', type: :hash,
                                      desc: 'Set the initial setup options'

      method_option :export_format, aliases: '-e', type: :string, default: 'yaml',
                                    desc: 'Output as ruby or yaml'

      method_option :pantry, aliases: '-p', type: :boolean, default: true,
                             desc: 'Save this recipe to the pantry as well'

      method_option :local_file, aliases: '-l', type: :boolean, default: false,
                                 desc: 'Whether to write out a local file with the contents'

      def add(*)
        if options[:help]
          invoke :help, ['add']
        else
          require_relative 'recipe/add'
          PiMaker::Commands::Recipe::Add.new(options).execute
        end
      end
    end
  end
end
