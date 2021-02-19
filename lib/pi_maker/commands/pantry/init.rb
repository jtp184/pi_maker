# frozen_string_literal: true

require_relative '../../command'

module PiMaker
  module Commands
    class Pantry
      class Init < PiMaker::Command
        def initialize(path, options)
          @path = path
          @options = options
        end

        def run(input: $stdin, output: $stdout)
          # Command logic goes here ...
          output.puts "OK"
        end

        def run_interactive(input: $stdin, output: $stdout)
          # Command logic goes here ...
          output.puts "OK"
        end
      end
    end
  end
end
