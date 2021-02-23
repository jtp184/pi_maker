# frozen_string_literal: true

require_relative '../../command'

module PiMaker
  module Commands
    class Recipe
      class List < PiMaker::Command
        def initialize(options)
          @options = options
        end

        def run(input: $stdin, output: $stdout)
          PiMaker::Pantry.global.recipes.each { |re| prompt.say(re.hostname) }
        end

        alias run_interactive run
      end
    end
  end
end
