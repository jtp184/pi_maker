# frozen_string_literal: true

require_relative '../../command'
require_relative '../helpers/collectors'

module PiMaker
  module Commands
    class Boot
      class Flash < PiMaker::Command
        include Helpers::Collectors
        def initialize(options)
          @options = options
        end

        def run(input: $stdin, output: $stdout)
        end

        def run_interactive(input: $stdin, output: $stdout)
          @disk = choose_disk
          binding.pry
        end
      end
    end
  end
end
