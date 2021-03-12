# frozen_string_literal: true

require_relative '../../command'
require_relative '../helpers'

module PiMaker
  module Commands
    class Remote
      class Connect < PiMaker::Command
        include Helpers

        def initialize(options)
          @options = options
        end

        def run(input: $stdin, output: $stdout)
          conf = parse_connection_config ||
                 (@options[:scan] && scan_for_host) ||
                 (@options[:interactive] && collect_connection_options)

          raise CLI::Error, 'No connection options given' unless conf

          conf = PiMaker.default_login.merge(conf)

          exec("ssh #{conf[:user]}@#{conf[:hostname]}")
        end

        alias run_interactive run

        private

        def scan_for_host
          hosts = PiMaker::NetworkIdentifier.call

          network = (@options[:interactive] && choose_identified_network(hosts)) || hosts.first

          return unless network

          case abbrev(%i[hostname ip_address], @options[:connect_with])
          when :hostname
            { hostname: network.hostname }
          when :ip_address
            { hostname: network.ip_address }
          end
        end
      end
    end
  end
end
