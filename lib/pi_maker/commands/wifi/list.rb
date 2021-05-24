# frozen_string_literal: true

require_relative '../../command'

module PiMaker
  module Commands
    class Wifi
      class List < PiMaker::Command
        def initialize(options)
          @options = options
        end

        def run(input: $stdin, output: $stdout)
          PiMaker::Pantry.global.wifi_networks.each do |ssid, passwd|
            prompt.say("#{ssid}#{@options[:passwords] ? %(: #{passwd}) : ''}")
          end
        end

        alias run_interactive run
      end
    end
  end
end
