# frozen_string_literal: true

require_relative '../../command'
require_relative '../helpers'

module PiMaker
  module Commands
    class Boot
      class Flash < PiMaker::Command
        include Helpers

        def initialize(options)
          @options = options
        end

        def run(input: $stdin, output: $stdout)
          raise CLI::Error, 'No image provided' unless @options[:image]
          raise CLI::Error, 'No disk provided' unless interpret_device_arg

          @disk = interpret_device_arg

          sudo_request

          @flashing = PiMaker::DiskManagement.write_image(@options[:image], @disk)

          nil until @flashing.finished?

          prompt.say("Wrote image to #{@disk}")
        end

        def run_interactive(input: $stdin, output: $stdout)
          @disk = interpret_device_arg || choose_disk
          @image = @options[:image] || prompt.ask('Path to image file: ')

          sudo_request

          @flashing = PiMaker::DiskManagement.write_image(@image, @disk)

          spinbar = spinner(
            '[:spinner] Writing image to card...',
            success_mark: '✅',
            error_mark: '❗️',
            frames: '🕒🕓🕔🕕🕖🕗🕘🕙🕚🕛🕐🕑',
            interval: 12
          )

          spinbar.auto_spin

          nil until @flashing.finished?

          spinbar.success("Wrote image to #{@disk}")
        end

        private

        def interpret_device_arg
          return nil unless @options[:device]

          PiMaker::DiskManagement.list_devices.detect { |d| d.inspect =~ /#{@options[:device]}/ }
        end
      end
    end
  end
end
