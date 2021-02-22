# frozen_string_literal: true

require_relative '../../command'

module PiMaker
  module Commands
    class Recipe
      class Delete < PiMaker::Command
        def initialize(hostname, options)
          @hostname = hostname
          @options = options
        end

        def run(input: $stdin, output: $stdout)
          raise CLI::Error 'No hostname' unless @hostname

          pantry = PiMaker::Pantry.global

          recipe = pantry.recipes.find { |r| r.hostname == @hostname }
          file_path = pantry.file_paths[recipe]

          generator.remove_file(file_path)
        end

        def run_interactive(input: $stdin, output: $stdout)
          pantry = PiMaker::Pantry.global
          recipes = pantry.recipes.map(&:hostname)

          remove = if @hostname
                     [@hostname]
                   else
                     prompt.multi_select('Delete which recipe(s)?', recipes)
                   end

          remove.map! { |hn| pantry.recipes.find { |r| r.hostname == hn } }

          remove.each do |rm|
            generator.remove_file(pantry.file_paths[rm])
          end
        end
      end
    end
  end
end
