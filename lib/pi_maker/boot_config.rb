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
            'pi4' => {
              'dtparam=audio' => 'on',
              'max_framebuffers' => '2'
            },
            'all' => {
              'dtoverlay' => 'vc4-fkms-v3d'
            }
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
        "[#{k}]\n#{v.map { |i, f| "#{i}=#{f}" }.join("\n")}"
      end.join("\n")
    end

    private

    # Takes the +file_contents+ and interprets them
    def parse_file(file_contents)
      set_lines = file_contents.split("\n").map do |line|
        next if line =~ /^$/
        next if line =~ /^#/

        [/^(\[)(.*)\]/, /(.*)=(.*)/].map { |ma| ma.match(line) }
                                    .compact
                                    .first
      end.compact

      opts = { all: {} }
      current_group = :all

      set_lines.each do |val|
        group_declare = val[1] == '['

        if group_declare
          current_group = val[2].to_sym
          opts[current_group] ||= {}
          next
        end

        opts[current_group][val[1]] = val[2]
      end

      OpenStruct.new(opts)
    end
  end
end
