# frozen_string_literal: true

require_relative '../command'

module PiMaker
  module Commands
    class Identify < PiMaker::Command
      def initialize(options)
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
