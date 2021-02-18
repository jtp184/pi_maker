# frozen_string_literal: true

require_relative '../../command'

module PiMaker
  module Commands
    class Wifi
      class Delete < PiMaker::Command
        def initialize(ssid, options)
          @ssid = ssid
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
