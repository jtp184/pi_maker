# frozen_string_literal: true

require_relative '../../command'
require_relative '../helpers'

module PiMaker
  module Commands
    class Boot
      class Config < PiMaker::Command
        include Helpers

        def initialize(options)
          @options = options
        end

        def run(input: $stdin, output: $stdout)
          raise CLI::Error, 'No values given' unless @options[:values] || @options[:interactive]

          @boot_config = interpret_boot_args || (@options[:interactive] && collect_boot_options)

          save_file
        end

        alias run_interactive run

        private

        def interpret_boot_args
          return unless @options[:values]

          PiMaker::BootConfig.new(config: @options[:values])
        end

        def save_file
          File.open(default_file_path, 'w+') { |f| f << @boot_config.to_s }
          prompt.ok("Saved to #{default_file_path}") if @options[:interactive]
        end

        def default_file_path
          "#{valid_default_path}/#{PiMaker::BootConfig::FILENAME}"
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
