# frozen_string_literal: true

require_relative '../../command'
require_relative '../helpers/collectors'

module PiMaker
  module Commands
    class Recipe
      class Add < PiMaker::Command
        include Helpers::Collectors

        def initialize(options)
          @options = options
        end

        def run(input: $stdin, output: $stdout)
          @recipe = PiMaker::Recipe.new(
            hostname: @options.fetch(:hostname),
            password: @options.fetch(:password),
            wpa_config: PiMaker::WpaConfig.new(@options.fetch(:wifi_options)),
            boot_config: PiMaker::BootConfig.new(@options.fetch(:boot_options)),
            initial_options: PiMaker::Ingredients.new(@options.fetch(:initial_options))
          )

          prompt.say("\n#{output_format}")
        end

        def run_interactive(input: $stdin, output: $stdout)
          @recipe = PiMaker::Recipe.new(
            hostname: prompt.ask('Hostname: '),
            password: prompt.mask('Password: '),
            wpa_config: collect_wifi_networks,
            boot_config: collect_boot_options,
            # TODO: add these
            # initial_options: collect_initial_options,
          )

          prompt.say("\n#{output_format}")
        end

        private

        def output_format
          case @options[:export_format]
          when 'yaml'
            @recipe.to_yaml
          when 'ruby'
            # TODO: Add exporter for define formatting
          end
        end
      end
    end
  end
end
