require 'ostruct'

module PiMaker
  # Wrapper for the config.txt file on the boot volume
  class BootConfig
    # The config object where options are set
    attr_reader :config
    # The path to save the file to
    attr_reader :path

    # Takes in +opts+ for the config and path
    def initialize(opts = {})
      @config = OpenStruct.new(
        opts.fetch(
          :config,
          {
            'dtparam=audio' => 'on',
            'dtoverlay' => 'vc4-fkms-v3d',
            'max_framebuffers' => '2'
          }
        )
      )

      @path = opts[:path]

      @path ||= case PiMaker.host_os
                when :mac
                  '/Volumes/boot'
                when :linux, :raspberrypi
                  '/mnt/boot'
                else
                  'E:/'
                end
    end

    # Pass arguments to config
    def method_missing(mtd_name, *args, &blk)
      config.public_send(mtd_name, *args, &blk)
    end

    # Output all config options as a stream of k=v
    def to_s
      config.to_h.map do |k, v|
        "#{k}=#{v}"
      end.join("\n")
    end
  end
end
