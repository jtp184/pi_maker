# frozen_string_literal: true

require_relative '../../command'

module PiMaker
  module Commands
    class Recipe
      class WriteBoot < PiMaker::Command
        def initialize(hostname, options)
          @hostname = hostname
          @options = options
        end

        def run(input: $stdin, output: $stdout)
          get_boot_config
          get_config_path

          File.open(@config_path, 'w+') do |fi|
            fi << @boot_config.to_s
          end

          prompt.ok("Saved to #{@config_path}")
        end

        alias run_interactive run

        private

        def get_config_path
          @config_path = if @options[:path]
            @options[:path]
          elsif default_exists?
            default_path
          elsif @options[:interactive]
            prompt.ask('Path to save to: ', default: default_path)
          else
            raise CLI::Error 'No config or path'
          end
        end

        def get_boot_config
          pantry = PiMaker::Pantry.global

          @boot_config = if @options[:interactive]
            recipe = pantry.recipes.find { |r| r.hostname == @hostname }
            return recipe if recipe

            recipes = pantry.recipes.map(&:hostname)
            search = prompt.select('Use which recipe?', recipes)

            pantry.recipes.find { |r| r.hostname == search }
          else
            raise CLI::Error 'No hostname' unless @hostname

            recipe = pantry.recipes.find { |r| r.hostname == @hostname }
            raise CLI::Error 'No recipe' unless recipe

            recipe
          end.boot_config
        end

        def default_exists?
          File.exist?(default_path)
        end

        def default_path
          [PiMaker.sd_card_path, PiMaker::BootConfig::FILENAME].join('/')
        end
      end
    end
  end
end
