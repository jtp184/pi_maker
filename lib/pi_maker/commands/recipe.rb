# frozen_string_literal: true

require 'thor'

module PiMaker
  module Commands
    class Recipe < Thor
      namespace :recipe

      desc 'delete [HOSTNAME]', 'Remove'

      method_option :help, aliases: '-h', type: :boolean,
                           desc: 'Display usage information'

      def delete(hostname = nil)
        if options[:help]
          invoke :help, ['delete']
        else
          require_relative 'recipe/delete'
          PiMaker::Commands::Recipe::Delete.new(hostname, options).execute
        end
      end

      desc 'list', 'Show all recipes from a certain collection'

      method_option :help, aliases: '-h', type: :boolean,
                           desc: 'Display usage information'
      def list(*)
        if options[:help]
          invoke :help, ['list']
        else
          require_relative 'recipe/list'
          PiMaker::Commands::Recipe::List.new(item, options).execute
        end
      end

      desc 'create', 'Create a new recipe'
      method_option :help, aliases: '-h', type: :boolean,
                           desc: 'Display usage information'

      method_option :hostname, aliases: '-n', type: :string,
                               desc: 'Set the hostname'

      method_option :password, aliases: '-p', type: :string,
                               desc: 'Set the password'

      method_option :wifi_options, aliases: '-w', type: :hash,
                                   desc: 'Set the hostname'

      method_option :boot_options, aliases: '-b', type: :hash,
                                   desc: 'Set the hostname'

      method_option :initial_options, aliases: '-t', type: :hash,
                                      desc: 'Set the hostname'

      def create(*)
        if options[:help]
          invoke :help, ['create']
        else
          require_relative 'recipe/create'
          PiMaker::Commands::Recipe::Create.new(options).execute
        end
      end
    end
  end
end
