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

    # Parses output from arp to get the hostname, IP, and MAC addresses
    ARP_PARSER = /
      (?<hostname>\?|[\w.-]+)\s
      \((?<ip_address>[[:xdigit:].:]+)\)
      \sat\s
      (?<mac_address>(?:[[:xdigit:]]{1,2}:?){6})
    /x.freeze

    # Parses the IP address line from nmap to return the hostname and ip_address
    NMAP_IP_PARSER = /
      for\s
      (?:
        (?:(?<hostname>[\w.-]+)\s\((?<ip_address>[\d.]+)\))
        |
        (?<ip_address>[\d.]+)
      )
    /x.freeze

    # Parses the MAC address line from nmap to return the MAC address and manufacturer name
    NMAP_MAC_PARSER = /
      MAC\sAddress:\s
      (?<mac_address>(?:[[:xdigit:]]{2}:?){6})
      \s
      \((?<manufacturer>.*)\)
    /x.freeze

    # Default program to run on mac and linux machines
    DEFAULT_PROGRAM = {
      mac: :arp,
      linux: :nmap,
      raspberry: :nmap
    }.freeze

    DEFAULT_IP_RANGE = -'192.168.1.0/24'

    # Structured result from running a scan program
    ScanResult = Struct.new(:hostname, :ip_address, :mac_address, :manufacturer) do
      def to_str
        ip_address
      end

      def to_s
        ip_address
      end
    end

    class << self
      # Takes in +opts+ for :scan_with, and optional overrides for run, parse, and filter with.
      # returns an array of ScanResult objects
      def call(opts = {})
        prog = opts.fetch(:scan_with, DEFAULT_PROGRAM[PiMaker.host_os])

        raise ArgumentError, "#{prog} is not installed" unless TTY::Which.which(prog.to_s)

        output = opts.fetch(:run_with) do
          case prog
          when :arp then -> { PiMaker.system_cmd('arp -a') }
          when :nmap then -> { PiMaker.system_cmd("sudo nmap -sn #{opts.fetch(:ip_address, DEFAULT_IP_RANGE)}") }
          else -> { PiMaker.system_cmd(prog.to_s) }
          end
        end.call

        results = opts.fetch(:parse_with) { method(:"parse_#{prog}") }.call(output)

        opts.fetch(:filter_with) do
          proc do |hosts|
            hosts.select do |host|
              host.manufacturer =~ /Raspberry Pi/ || MAC_RANGES.include?(host.mac_address&.[](0..2))
            end
          end
        end.call(results)
      end

      private

      # Converts a mac address into an array of hex couplets
      def convert_mac_address(mac_addr)
        mac_addr.split(':')
                .map { |addr| addr.to_i(16) }
                .map { |addr| format('%02X', addr) }
      end

      # Parses the +hosts+ from arp into ScanResult objects
      def parse_arp(hosts)
        hosts.split("\n")
             .map { |l| l.match(ARP_PARSER) }
             .compact
             .map(&:named_captures)
             .map { |nc| ScanResult.new(*nc.values) }
             .map { |sr| sr.tap { |r| r.mac_address = convert_mac_address(sr.mac_address) } }
      end

      # Parses the text from +nmap+ into ScanResult objects
      def parse_nmap(nmap)
        nmap.split("\n")[1..-2].each_slice(3).map do |ip_str, _up_str, mf_str|
          ip_cap = ip_str.match(NMAP_IP_PARSER).named_captures
          mac_cap = mf_str ? mf_str.match(NMAP_MAC_PARSER).named_captures : {}

          if mac_cap['mac_address']
            mac_cap['mac_address'] = convert_mac_address(mac_cap['mac_address'])
          end

          ScanResult.new(*ip_cap.merge(mac_cap).values)
        end
      end
    end
  end
end
