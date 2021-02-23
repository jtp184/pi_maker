# frozen_string_literal: true

require_relative '../../command'

module PiMaker
  module Commands
    class Pantry
      class Encrypt < PiMaker::Command
        def initialize(password, options)
          @password = password
          @options = options
        end

        def run(input: $stdin, output: $stdout)
          @pantry = PiMaker::Pantry.global
          FileUtils.rm_rf(@pantry.base_path)

          @pantry.password = @password ||
                             (prompt.ask('Password: ') if @options[:interactive])

          @pantry.write
          prompt.ok("Wrote to #{@pantry.base_path}")
        end

        alias run_interactive run
      end
    end
  end
end
