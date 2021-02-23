require 'ostruct'

module PiMaker
  # Wrapper for the config.txt file on the boot volume
  class BootConfig
    # The config object where options are set
    attr_reader :config
    # Enable ssh on the boot volume
    attr_reader :ssh

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

    # Filename on disk
    FILENAME = 'config.txt'.freeze

    # Parse the +yml+ string and create a new instance from it
    def self.from_yaml(yml, encrypted = nil)
      new(Psych.load(FileEncrypter.decrypt(yml, encrypted)))
    end

    # Takes in +opts+ for the config and path
    def initialize(opts = {})
      @ssh = opts.key?(:ssh) ? opts.delete(:ssh) : true

      if opts.key?(:path)
        @config = parse_file(File.read(opts[:path]))
      else
        @config = OpenStruct.new

        opts.fetch(:config, default_config).each do |key, value|
          if FILTERS.include?(key.to_s) && value.is_a?(Hash)
            @config[key] ||= OpenStruct.new
            value.each { |k, v| @config[key][k] = v }
          else
            @config['all'] ||= OpenStruct.new
            @config['all'][key] = value
          end
        end
      end
    end

    FILTERS.each do |fil|
      next unless fil =~ /[a-z0-9_]/i

      define_method(fil.to_sym) do
        self[fil]
      end
    end

    # Get the +key+ from the config, defaulting to all if it isn't a filter
    def [](key)
      if FILTERS.include?(key)
        config[key] ||= OpenStruct.new
      else
        config['all'][key]
      end
    end

    # Set the +key+ to the +value+, defaulting to all if it isn't a filter
    def []=(key, value)
      if FILTERS.include?(key)
        config[key] ||= OpenStruct.new
        config[key] = value
      else
        config['all'][key] ||= OpenStruct.new
        config['all'][key] = value
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

    # Return a hash representation
    def to_h
      { ssh: ssh, config: deep_hashify }
    end

    # Dump the hash representation, taking in an optional +password+ to encrypt with
    def to_yaml(password = nil)
      yml = Psych.dump(to_h)

      FileEncrypter.encrypt(yml, password)
    end

    # Pass the +mtd_name+ as a subargument of all if missing
    def method_missing(mtd_name, *args, &block)
      self['all'].send(mtd_name, *args, &block)
    rescue NoMethodError
      super
    end

    # Responds to +mtd_name+ and returns whether we have a key already for all
    def respond_to_missing?(mtd_name, priv = false)
      self['all'].to_h.key?(mtd_name) || super
    end

    private

    # Given the starting +note+, recursively transforms the subvalues to hashes
    def deep_hashify(node = config)
      node.to_h.transform_values do |v|
        v.respond_to?(:to_h) ? deep_hashify(v) : v
      end
    end

    # The default options
    def default_config
      {
        'pi4' => {
          'dtparam=audio' => 'on',
          'max_framebuffers' => '2'
        },
        'all' => {
          'dtoverlay' => 'vc4-fkms-v3d'
        }
      }
    end

    # Takes the +file_contents+ and interprets them
    def parse_file(file_contents)
      set_lines = extract_actionable_lines(file_contents)

      opts = { 'all' => {} }
      current_group = 'all'

      set_lines.each do |val|
        group_declare = val[1] == '['

        if group_declare
          current_group = val[2]
          opts[current_group] ||= {}
          next
        end

        opts[current_group][val[1]] = val[2]
      end

      OpenStruct.new(opts.transform_values { |v| OpenStruct.new(v) })
    end

    # Extracts non empty and non comment lines from +file_contents+
    def extract_actionable_lines(file_contents)
      file_contents.split("\n").map do |line|
        next if line =~ /^$/
        next if line =~ /^#/

        [/^(\[)(.*)\]/, /(.*)=(.*)/].map { |ma| ma.match(line) }
                                    .compact
                                    .first
      end.compact
    end
  end
end
