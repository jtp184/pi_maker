# frozen_string_literal: true

require_relative '../../command'

module PiMaker
  module Commands
    class Pantry
      class Decrypt < PiMaker::Command
        def initialize(password, options)
          @password = password
          @options = options
        end

        def run(input: $stdin, output: $stdout)
          pantry = PiMaker::Pantry.global(password: pantry_password)
                                  .tap(&:recipes)
                                  .tap(&:wifi_networks)

          FileUtils.rm_rf(pantry.base_path)
          pantry.password = nil

          pantry.write
          prompt.ok('Decrypted pantry')
        end

        alias run_interactive run

        private

        def pantry_password
          if @password
            @password
          elsif global_pantry_password_file
            global_pantry_password_file
          elsif @options[:interactive]
            prompt.mask('Password: ')
          else
            raise CLI::Error, 'No password'
          end
        end

        def global_pantry_password_file
          return nil unless PiMaker::Pantry.global_exists?

          passfile = "#{PiMaker::Pantry.global_exists?}/.pi_maker/.pantry_password"

          return nil unless File.exist?(passfile)

          File.read(passfile)
        end
      end
    end
  end
end
