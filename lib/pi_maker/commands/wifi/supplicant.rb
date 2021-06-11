# frozen_string_literal: true

require_relative '../../command'
require_relative '../helpers'

module PiMaker
  module Commands
    class Wifi
      class Supplicant < PiMaker::Command
        include Helpers

        def initialize(options)
          @options = options
        end

        def run(input: $stdin, output: $stdout)
          raise CLI::Error, 'No credentials' unless @options[:credentials]
          raise CLI::Error, 'No valid default path' unless valid_default_path

          @wpa_config = PiMaker::WpaConfig.new(networks: @options[:credentials])

          save_file
        end

        def run_interactive(input: $stdin, output: $stdout)
          @wpa_config = if @options[:credentials]
                          PiMaker::WpaConfig.new(networks: @options[:credentials])
                        else
                          collect_wifi_networks
                        end

          save_file
        end

        private

        def save_file
          File.open(default_file_path, 'w+') { |f| f << @wpa_config.to_s }
          prompt.ok("Saved to #{default_file_path}") if @options[:interactive]
        end

        def default_file_path
          "#{valid_default_path}/#{PiMaker::WpaConfig::FILENAME}"
        end

        def valid_default_path
          [PiMaker.sd_card_path, @options[:save], Dir.pwd].compact.detect do |fp|
            Dir.exist?(File.absolute_path(fp))
          end
        end
      end
    end
  end
end
