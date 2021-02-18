# frozen_string_literal: true

require 'thor'

module PiMaker
  module Commands
    class Pantry < Thor
      namespace :pantry

      desc 'list', 'List records'

      def list(*)
        if options[:help]
          invoke :help, ['list']
        else
          require_relative 'pantry/list'
          PiMaker::Commands::Pantry::List.new(options).execute
        end
      end

      desc 'init [PATH]', 'Create a pantry folder'

      def init(path = nil)
        if options[:help]
          invoke :help, ['init']
        else
          require_relative 'pantry/init'
          PiMaker::Commands::Pantry::Init.new(path, options).execute
        end
      end
    end
  end
end
