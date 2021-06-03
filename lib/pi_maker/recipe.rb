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
    # An Instructions to set install options
    attr_accessor :initial_setup
    # Other Instructions sets to apply
    attr_accessor :additional_setup

    # Takes in +opts+ for the attributes
    def initialize(opts = {})
      %i[hostname password wpa_config boot_config initial_setup additional_setup].each do |key|
        instance_variable_set("@#{key}", opts[key]) if opts[key]
      end

      parse_wifi_config_options(opts)
      parse_boot_config_options(opts)
      parse_initial_config_options(opts)
      parse_additional_setups(opts)
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

      inst.parse_wifi_config_options(yaml)
      inst.parse_boot_config_options(yaml)
      inst.parse_initial_config_options(yaml)
      inst.parse_additional_setups(yaml)

      inst
    end

    # Returns an Instructions list to set the hostname and password on the pi
    def login_setup(old_password = PiMaker.default_login[:password])
      Instructions.define do |i|
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

      if additional_setup
        data[:additional_setup_options] = additional_setup.transform_values(&:to_h)
      end

      data
    end

    # Dumps the hash to YAML, taking in +opts+ to pass to to_h, and an optional encryption +passwd+
    def to_yaml(passwd = nil, opts = {})
      yml = Psych.dump(to_h(opts))
      FileEncrypter.encrypt(yml, passwd)
    end

    # Parses the initial config options
    def parse_initial_config_options(opts)
      return unless opts.to_h.key?(:initial_setup_options)

      self.initial_setup ||= Instructions.new(opts[:initial_setup_options])
    end

    # Parses any additional setup options provided
    def parse_additional_setups(opts)
      return unless opts.to_h.key?(:additional_setup_options)

      self.additional_setup ||= opts[:additional_setup_options].transform_values do |ins|
        Instructions.new(ins)
      end
    end

    # Parses the boot config options
    def parse_boot_config_options(opts)
      return unless opts.to_h.key?(:boot_config_options)

      self.boot_config ||= BootConfig.new(opts[:boot_config_options])
    end

    # Parses the wifi config options
    def parse_wifi_config_options(opts)
      return unless opts.to_h.key?(:wifi_config_options)

      conf = opts[:wifi_config_options]
      self.wpa_config ||= WpaConfig.new(conf.slice(:country_code))

      conf[:networks].each do |args|
        if args.is_a?(Array)
          self.wpa_config.append(*args)
        elsif args.is_a?(String)
          Pantry.global.wifi_networks[args]
        end
      end
    end
  end
end
