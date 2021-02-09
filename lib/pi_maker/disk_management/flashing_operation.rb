require 'io/wait'

module PiMaker
  module DiskManagement
    # Wraps a pipe running dd to write the image to the SD card
    class FlashingOperation
      attr_reader :image_path, :disk

      # Creates a new instance and runs #call on it
      def self.start(opts = {})
        new(opts).call
      end

      # Takes in +opts+ for image_path and disk
      def initialize(opts = {})
        @image_path = opts.fetch(:image_path)
        @disk = opts.fetch(:disk)
      end

      # Creates pipe running dd and returns the instance with the pipe running
      def call
        @pipe = IO.popen(
          "sudo dd bs=1m if=#{image_path} of=#{disk.raw_disk_path}",
          err: %i[child out]
        )

        self
      end

      # Returns true once the pipe is ready for reading, which indicates completeness
      def finished?
        return unless @pipe

        @pipe.ready?
      end
    end
  end
end
