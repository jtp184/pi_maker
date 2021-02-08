require 'tty-which'

module PiMaker
  # Locate a pi on the network
  module NetworkIdentifier
    # Registered Raspi MAC addresses
    MAC_RANGES = [
      %w[B8 27 EB],
      %w[DC A6 32],
      %w[E4 5F 01]
    ].freeze

    class << self
      # Takes in +opts+ for :scan_with program, returns an array of ips
      def call(opts = {})
        prog = opts.fetch(:scan_with, :arp)

        hosts = send(:"run_#{prog}", opts)
        hosts = send(:"parse_#{prog}", hosts)

        send(:"filter_#{prog}", hosts)
      end

      private

      # Converts a mac address into an array of hex couplets
      def convert_mac_address(arp)
        arp.split(':')
           .map { |addr| addr.to_i(16) }
           .map { |addr| format('%02X', addr) }
      end

      # Takes the +hosts+ and returns only those whose MAC begins with one of the constants
      def filter_arp(hosts)
        hosts.select do |_ipaddr, mac_address|
          MAC_RANGES.include?(mac_address[0..2])
        end.map(&:first)
      end

      # Takes the +hosts+ and returns only the ones which have raspi as manufacturer
      def filter_nmap(hosts)
        hosts.select do |_ipaddr, manufacturer|
          manufacturer =~ /Raspberry Pi/
        end.map(&:first)
      end

      # Parses the +hosts+ from arp
      def parse_arp(hosts)
        hosts.split("\n")
             .map { |l| l.match(/\(((?:\d+\.?){4})\) at ([a-f0-9:]+) on/) }
             .compact
             .map(&:captures)
             .to_h
             .transform_values { |l| convert_mac_address(l) }
      end

      # Takes in a string result from +nmap+, and converts it into a tuple of ip address
      # and the manufacturer
      def parse_nmap(nmap)
        nmap.split("\n")[1..-2].each_slice(3).map do |ip_str, _up_str, mf_str|
          [
            ip_str.match(/\((.*)\)/)[1],
            mf_str ? mf_str.match(/\((.*)\)/)[1] : 'Unknown'
          ]
        end
      end

      # Performs the nmap command
      def run_nmap(opts = {})
        PiMaker.system_cmd("sudo nmap -sn #{opts.fetch(:ip_address, '192.168.1.0/24')}")
      end

      # Performs the arp command
      def run_arp(_opts = {})
        PiMaker.system_cmd('arp -a')
      end
    end
  end
end
