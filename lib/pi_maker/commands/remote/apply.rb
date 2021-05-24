# frozen_string_literal: true

require_relative '../../command'
require_relative '../helpers'

module PiMaker
  module Commands
    class Remote
      class Apply < PiMaker::Command
        include Helpers

        def initialize(reference, options)
          @reference = reference
          @options = options

          @hostname, @setup_name = parse_hierarchy(@reference)
        end

        def run(input: $stdin, output: $stdout)
          conf = parse_connection_config ||
                 (@options[:scan] && scan_for_host) ||
                 (@options[:interactive] && collect_connection_options)

          raise CLI::Error, 'No connection options given' unless conf
          raise CLI::Error, 'No recipe given' unless @reference || @options[:interactive]

          if @options[:verbose]
            runner.call do |l|
              prompt.say(pastel.light_black(l))
            end
          else
            runner.call
          end

          prompt.ok('Applied setup')
        end

        alias run_interactive run

        private

        def runner
          @runner = PiMaker::RemoteRunner.new(
            config: PiMaker.default_login.merge(@config || {}),
            command_group: PiMaker::CommandGroup.new(setup)
          )
        end

        def setup
          return @setup if @setup

          setup = if @setup_name
                    recipe.additional_setup.find { |key, _ins| key == @setup_name.to_sym }
                  end

          if @setup.nil?
            recipe.initial_setup
          elsif @options[:interactive] && setup.nil?
            setups = recipe.additional_setup.transform_keys(&:to_s)
            setups[prompt.select('Use which setup?', setups.keys).to_sym]
          else
            raise CLI::Error, 'No setup exists' unless setup
          end
        end

        # Get the recipe from the reference, or a prompt if running interactively
        def recipe
          return @recipe if @recipe

          pantry = PiMaker::Pantry.global

          @recipe = begin
            recipe = pantry.recipes.find { |r| r.hostname == @hostname }

            if recipe
              recipe
            elsif @options[:interactive] && recipe.nil?
              recipes = pantry.recipes.map { |r| [r.hostname, r] }.to_h
              recipes[prompt.select('Use which recipe?', recipes.keys)]
            elsif recipe.nil?
              raise CLI::Error, 'No recipe' unless recipe
            end
          end
        end

        def parse_hierarchy(argv)
          return [nil, nil] unless argv

          argv.split('.')
        end
      end
    end
  end
end
