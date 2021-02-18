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

        def execute(input: $stdin, output: $stdout)
          # Command logic goes here ...
          output.puts "OK"
        end
      end
    end
  end
end
