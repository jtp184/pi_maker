# frozen_string_literal: true

require_relative '../command'

module PiMaker
  module Commands
    class Identify < PiMaker::Command
      def initialize(options)
        @options = options
      end

      def run(input: $stdin, output: $stdout)
        res = PiMaker::NetworkIdentifier.call(args)
        res.empty? ? abort : res.each { |r| prompt.say(r) }
      end

      alias run_interactive run

      private

      def args
        pr = @program || (@options[:interactive] && prompt.ask('Use which program: ', default: :arp))
        ip = @range || (@options[:interactive] && prompt.ask('IP Range: ', default: '192.168.1.0/24'))

        ret = {}

        ret[:scan_with] = pr if pr
        ret[:ip_range] = ip if ip

        ret
      end
    end
  end
end
