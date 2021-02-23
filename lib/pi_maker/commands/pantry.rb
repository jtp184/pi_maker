# frozen_string_literal: true

require 'thor'

module PiMaker
  module Commands
    class Pantry < Thor
      namespace :pantry

      desc 'init [PATH]', 'Create a pantry folder'

      method_option :overwrite, aliases: '-o', type: :boolean,
                                desc: 'Overwrite existing pantry'

      def init(path = nil)
        if options[:help]
          invoke :help, ['init']
        else
          require_relative 'pantry/init'
          PiMaker::Commands::Pantry::Init.new(path, options).execute
        end
      end

      desc 'encrypt [PASSWORD]', 'Encrypt the pantry folder'

      def encrypt(password = nil)
        if options[:help]
          invoke :help, ['encrypt']
        else
          require_relative 'pantry/encrypt'
          PiMaker::Commands::Pantry::Encrypt.new(password, options).execute
        end
      end

      desc 'decrypt [PASSWORD]', 'Decrypt the pantry folder'

      def decrypt(password = nil)
        if options[:help]
          invoke :help, ['decrypt']
        else
          require_relative 'pantry/decrypt'
          PiMaker::Commands::Pantry::Decrypt.new(password, options).execute
        end
      end
    end
  end
end
