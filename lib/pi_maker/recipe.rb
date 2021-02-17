require 'psych'

module PiMaker
  # Define a pi and its dependencies and config options
  class Recipe
    # A hostname to set instead of raspberrypi
    attr_accessor :hostname
    # A password to set instead of raspberry
    attr_accessor :password
    # A WifiConfig to install on the card
    attr_accessor :wpa_config
    # A BootConfig to install on the card
    attr_accessor :boot_config
    # An Ingredients to set install options
    attr_accessor :initial_setup

    # Takes in +opts+ for the attributes
    def initialize(opts = {})
      %i[hostname password wpa_config boot_config initial_setup].each do |key|
        instance_variable_set("@#{key}", opts[key]) if opts[key]
      end
    end

    # Yield to a block, or directly use the +hsh+ to create a new instance
    def self.define(hsh = {})
      opts = OpenStruct.new(hsh)
      yield opts if block_given?
      new(opts)
    end

    # Takes in the +yml+ string, loads the options from it and returns a new instance
    def self.from_yaml(yml, encrypted = nil)
      yaml = Psych.load(FileEncrypter.decrypt(yml, encrypted))

      inst = new(yaml.slice(:hostname, :password))

      parse_wifi_config_options(inst, yaml)
      parse_boot_config_options(inst, yaml)
      parse_initial_config_options(inst, yaml)

      inst
    end

    # Returns an Ingredients list to set the hostname and password on the pi
    def login_setup(old_password = PiMaker.default_login[:password])
      Ingredients.define do |i|
        i.raspi_config = { do_hostname: hostname }
        i.shell = [
          format(
            %{(echo "%<old_pass>s" ; echo "%<new_pass>s" ; echo "%<new_pass>s") | passwd},
            old_pass: old_password,
            new_pass: password
          )
        ]
      end
    end

    # Takes in +opts+ for whether to export :with_passwords, and returns a hash representation
    def to_h(opts = {})
      data = {}

      %i[hostname password].each { |k| data[k] = send(k) if send(k) }

      data[:wifi_config_options] = wpa_config.to_h(opts.fetch(:with_passwords, true)) if wpa_config
      data[:boot_config_options] = boot_config.to_h if boot_config
      data[:initial_setup_options] = initial_setup.to_h if initial_setup

      data
    end

    # Dumps the hash to YAML, taking in +opts+ to pass to to_h, and an optional encryption +passwd+
    def to_yaml(passwd = nil, opts = {})
      yml = Psych.dump(to_h(opts))
      FileEncrypter.encrypt(yml, passwd)
    end

    class << self
      private

      # Parses the initial config options
      def parse_initial_config_options(inst, opts)
        return unless opts.key?(:initial_setup_options)

        inst.initial_setup ||= Ingredients.new(opts[:initial_setup_options])
      end

      # Parses the boot config options
      def parse_boot_config_options(inst, opts)
        return unless opts.key?(:boot_config_options)

        inst.boot_config ||= BootConfig.new(opts[:boot_config_options])
      end

      # Parses the wifi config options
      def parse_wifi_config_options(inst, opts)
        return unless opts.key?(:wifi_config_options)

        conf = opts[:wifi_config_options]
        inst.wpa_config ||= WpaConfig.new(conf.slice(:country_code))

        conf[:networks].each do |args|
          next unless [Array, String].detect { |c| args.is_a?(c) }

          # TODO: in place ssid
          inst.wpa_config.append(*args) if args.respond_to?(:[])
        end
      end
    end
  end
end
