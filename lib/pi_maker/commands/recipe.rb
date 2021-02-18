# frozen_string_literal: true

require 'thor'

module PiMaker
  module Commands
    class Recipe < Thor

      namespace :recipe

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
