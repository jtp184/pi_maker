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
      @path = opts.fetch(:path) do
        case PiMaker.host_os
        when :mac
          '/Volumes/boot/config.txt'
        when :linux, :raspberrypi
          '/mnt/boot/config.txt'
        else
          'E:/config.txt'
        end
      end

      @config = opts.fetch(:config) do
        if File.exist?(path)
          parse_file(File.read(path))
        else
          OpenStruct.new(
            'dtparam=audio' => 'on',
            'dtoverlay' => 'vc4-fkms-v3d',
            'max_framebuffers' => '2'
          )
        end
      end
    end

    # Pass arguments to config
    def method_missing(mtd_name, *args, &blk)
      config.public_send(mtd_name, *args, &blk) || super
    end

    # Respond to the config's messages
    def respond_to_missing?(mtd_name, priv = false)
      config.respond_to?(mtd_name, priv) || super
    end

    # Output all config options as a stream of k=v
    def to_s
      config.to_h.map do |k, v|
        "#{k}=#{v}"
      end.join("\n")
    end

    private

    # Takes the +file_contents+ and interprets them
    def parse_file(file_contents)
      opts = file_contents.split("\n").map do |line|
        next if line =~ /^#/
        next if line =~ /^$/
        next unless line =~ /=/

        line.match(/(.*)=(.*)/).captures
      end.compact.to_h

      OpenStruct.new(opts)
    end
  end
end
