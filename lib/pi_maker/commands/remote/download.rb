# frozen_string_literal: true

require_relative '../../command'

module PiMaker
  module Commands
    class Remote
      class Download < PiMaker::Command
        def initialize(local_file, remote_file, options)
          @local_file = local_file
          @remote_file = remote_file
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
