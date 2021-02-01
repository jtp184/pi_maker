require 'tty-which'

module PiMaker
  # Locate a pi on the network
  module NetworkIdentifier
    class << self
      # Takes in +opts+ for :ip_range, and runs the nmap
      def call(opts = {})
        check_nmap

        hosts = parse_nmap(run_nmap(opts.fetch(:ip_range, '192.168.1.0/24')))

        hosts.select! do |_ip, manufacturer|
          manufacturer =~ /Raspberry Pi/i
        end.map(&:first)
      end

      private

      # Check that nmap is installed
      def check_nmap
        return if TTY::Which.exist?('nmap')

        raise LoadError, 'Please install nmap before using this class'
      end

      # Takes in a string result from +nmap+, and converts it into a tuple of ip address
      # and the manufacturer
      def parse_nmap(nmap)
        nmap.split("\n")[1..-2].each_slice(3).map do |ip_str, _up_str, mf_str|
          [
            ip_str.split(' ').last,
            mf_str ? mf_str.match(/\((.*)\)/)[1] : 'Unknown'
          ]
        end
      end

      # Given an +ip_range+, runs nmap and returns the results
      def run_nmap(ip_range)
        `sudo nmap -sn #{ip_range}`
      end
    end
  end
end
