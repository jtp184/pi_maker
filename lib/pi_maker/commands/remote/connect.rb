# frozen_string_literal: true

require_relative '../../command'
require_relative '../helpers'

module PiMaker
  module Commands
    class Remote
      class Connect < PiMaker::Command
        include Helpers

        def initialize(reference, options)
          @reference = reference
          @options = options
        end

        def run(input: $stdin, output: $stdout)
          conf = parse_connection_reference || (@options[:interactve] && collect_connection_options)

          raise CLI::Error 'No connection options given' unless conf

          conf = PiMaker.default_login.merge(conf)

          puts("ssh #{conf[:user]}@#{conf[:hostname]}")
        end

        def run_interactive(input: $stdin, output: $stdout)
        end
      end
    end
  end
end
