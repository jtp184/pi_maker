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
        res.empty? ? abort : res.each { |r| prompt.say(output_item(r)) }
      end

      alias run_interactive run

      private

      def args
        pr = (@options[:interactive] && program_prompt) || @options[:program]
        ip = (@options[:interactive] && ip_prompt) || @options[:range]

        ret = {}

        ret[:scan_with] = pr.to_sym if pr
        ret[:ip_range] = ip if ip

        ret
      end

      def output_item(result)
        case output_option
        when :hostname then result.hostname
        when :ip then result.ip_address
        when :both then "#{result.hostname} (#{result.ip_address})"
        end
      end

      def ip_prompt
        prompt.ask('IP Range: ', default: '192.168.1.0/24')
      end

      def program_prompt
        prompt.ask(
          'Use which program: ',
          default: PiMaker::NetworkIdentifier::DEFAULT_PROGRAM
        )
      end

      def output_option
        abbrev(%i[hostname ip both], @options[:output])
      end
    end
  end
end
