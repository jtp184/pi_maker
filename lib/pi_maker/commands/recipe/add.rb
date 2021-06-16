# frozen_string_literal: true

require_relative '../../command'
require_relative '../helpers'

module PiMaker
  module Commands
    class Recipe
      class Add < PiMaker::Command
        include Helpers

        def initialize(options)
          @options = options
        end

        def run(input: $stdin, output: $stdout)
          @recipe = PiMaker::Recipe.new(
            hostname: @options.fetch(:hostname),
            password: @options.fetch(:password),
            wpa_config: PiMaker::WpaConfig.new(networks: @options.fetch(:wifi_options)),
            boot_config: PiMaker::BootConfig.new(
              config: @options.fetch(:boot_options),
              ssh: @options.fetch(:ssh)
            ),
            initial_setup: PiMaker::Instructions.new(
              @options.fetch(:initial_setup).transform_values { |v| v.split(',') }
            )
          )

          save_and_output
        end

        def run_interactive(input: $stdin, output: $stdout)
          @recipe = PiMaker::Recipe.new(
            hostname: prompt.ask('Hostname: '),
            password: prompt.mask('Password: '),
            wpa_config: collect_wifi_networks,
            boot_config: collect_boot_options,
            initial_setup: collect_instructions
          )

          save_and_output
        end

        private

        def save_and_output
          if @options[:pantry]
            save_to_pantry
            prompt.ok('Saved to pantry')
          end

          if @options[:local_file]
            filename = "./#{@recipe.hostname}_recipe.yml"

            File.open(filename, 'w+') do |f|
              f << @recipe.to_yaml
            end

            prompt.ok("Saved to #{filename}")
          end

          prompt.say("\n#{output_format}")
        end

        def save_to_pantry
          pantry = PiMaker::Pantry.global
          pantry.recipes << @recipe
          pantry.write
        end

        def output_format
          case @options[:export_format]
          when 'yaml'
            @recipe.to_yaml
          when 'ruby'
            @recipe.to_rb
          end
        end
      end
    end
  end
end
