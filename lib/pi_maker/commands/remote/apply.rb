# frozen_string_literal: true

require_relative '../../command'

module PiMaker
  module Commands
    class Remote
      class Apply < PiMaker::Command
        def initialize(reference, options)
          @reference = reference
          @options = options
        end

        def run(input: $stdin, output: $stdout)
        end

        def run_interactive(input: $stdin, output: $stdout)
        end
      end
    end
  end
end