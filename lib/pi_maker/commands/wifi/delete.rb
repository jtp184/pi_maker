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

        def run(input: $stdin, output: $stdout)
          raise CLI::Error, 'No ssid' unless @ssid

          pantry = PiMaker::Pantry.global

          pantry.wifi_networks.delete(@ssid)
          prompt.say("Removed #{pastel.red(@ssid)}")

          pantry.write
        end

        def run_interactive(input: $stdin, output: $stdout)
          pantry = PiMaker::Pantry.global
          recipes = pantry.wifi_networks.keys

          remove = @ssid ? [@ssid] : prompt.multi_select('Delete which recipe(s)?', recipes)

          remove.each do |rm|
            pantry.wifi_networks.delete(rm)
            prompt.say("Removed #{pastel.red(rm)}")
          end

          pantry.write
        end
      end
    end
  end
end
