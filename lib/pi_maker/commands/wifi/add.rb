# frozen_string_literal: true

require_relative '../../command'
require_relative '../helpers'

module PiMaker
  module Commands
    class Wifi
      class Add < PiMaker::Command
        include Helpers

        def initialize(ssid, passwd, options)
          @ssid = ssid
          @passwd = passwd
          @options = options
        end

        def run(input: $stdin, output: $stdout)
          append_globally(@ssid, @passwd)
          prompt.ok('Saved to pantry')
        end

        def run_interactive(input: $stdin, output: $stdout)
          collect_wifi_networks.networks.each { |k, v| append_globally(k, v) }
          prompt.ok('Saved to pantry')
        end

        private

        def append_globally(ssid, passwd)
          global = PiMaker::Pantry.global
          global.wifi_networks.merge!(ssid => passwd)
          global.write
        end
      end
    end
  end
end
