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

        def execute(input: $stdin, output: $stdout)
          # Command logic goes here ...
          output.puts "OK"
        end
      end
    end
  end
end
