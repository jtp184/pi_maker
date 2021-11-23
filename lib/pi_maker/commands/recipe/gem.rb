# frozen_string_literal: true

require_relative '../../command'

module PiMaker
  module Commands
    class Recipe
      class Gem < PiMaker::Command
        def initialize(gemname, options)
          @gemname = gemname
          @options = options
        end

        def run_interactive(input: $stdin, output: $stdout)
          args = {
            hostname: prompt.ask('Hostname: ', default: @gemname),
            password: prompt.mask('Password: '),
            wpa_config: collect_wifi_networks,
            boot_config: collect_boot_options,
          }

          @recipe = PiMaker::Recipe.new(gem_recipe.merge(args))

          save_and_output
        end

        def run(input: $stdin, output: $stdout)
          args = {
            hostname: options[:hostname] || "#{@gemname}-pi",
            password: options[:password],
            wpa_config: options[:wifi_options],
          }

          @recipe = PiMaker::Recipe.new(gem_recipe.merge(args))

          save_and_output
        end

        private

        def gem_recipe
          require Strings::Case.underscore(@gemname)

          gem_class = const_get(Strings::Case.pascal_case(@gemname))
          gem_class.pi_maker_recipe
        end

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
