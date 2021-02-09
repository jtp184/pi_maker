require 'ostruct'

module PiMaker
  # Wrapper for the config.txt file on the boot volume
  class BootConfig
    # The config object where options are set
    attr_reader :config
    # The path to save the file to
    attr_reader :path

    # The different groups a config option can belong to
    FILTERS = %w[
      all
      pi1
      pi2
      pi3
      pi3+
      pi4
      pi0
      pi0w
    ].freeze

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
          OpenStruct.new(default_config)
        end
      end
    end

    # Pass arguments to config
    def method_missing(mtd_name, *args, &blk)
      if FILTERS.include?(mtd_name.to_s)
        config.public_send(mtd_name, *args, &blk)
      else
        config.public_send(:all)
              .public_send(mtd_name, *args, &blk)
      end || super
    end

    # Respond to the config's messages
    def respond_to_missing?(mtd_name, priv = false)
      FILTERS.include?(mtd_name.to_s) || config.respond_to?(mtd_name, priv) || super
    end

    # Get the +key+ from the config
    def [](key)
      if FILTERS.include?(key)
        config[key] ||= OpenStruct.new
      else
        config['all'][key]
      end
    end

    # Output all config options as a stream of k=v
    def to_s
      s = +''

      config.to_h.sort.reverse.each do |k, v|
        s << "[#{k}]\n"

        v.to_h.each { |i, f| s << "#{i}=#{f}\n" }
      end

      s << "\n"
    end

    private

    # The default options
    def default_config
      conf = {
        'pi4' => {
          'dtparam=audio' => 'on',
          'max_framebuffers' => '2'
        },
        'all' => {
          'dtoverlay' => 'vc4-fkms-v3d'
        }
      }.transform_values { |v| OpenStruct.new(v) }

      OpenStruct.new(conf)
    end

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
