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
        instance_variable_set("@#{key}", opts[key]) if opts.key?(key)
      end
    end

    # Yield to a block, or directly use the +hsh+ to create a new instance
    def self.define(hsh = {})
      opts = OpenStruct.new(hsh)
      yield opts if block_given?
      new(opts)
    end

    # Takes in the +yml+ string, loads the options from it and returns a new instance
    def self.from_yaml(yml)
      yaml = Psych.load(yml)

      inst = new(yaml.slice(:hostname, :password))

      if yaml.key?(:wifi_config_options)
        inst.wpa_config = WpaConfig.new

        yaml[:wifi_config_options][:networks].each do |wifi|
          next unless [Hash, String].detect { |c| wifi.is_a?(c) }

          # TODO: in place ssid
          wifi.respond_to?(:[]) ? inst.wpa_config.append(*wifi.first) : nil
        end
      end

      if yaml.key?(:boot_config_options)
        inst.boot_config = BootConfig.new

        yaml[:boot_config_options].each do |key, value|
          inst.boot_config.public_send(:"#{key}=", value)
        end
      end

      if yaml.key?(:initial_setup_options)
        inst.initial_setup = Ingredients.new(yaml[:initial_setup_options])
      end

      inst
    end

    # Takes in +opts+ for whether to export :with_passwords, and returns a hash representation
    def to_h(opts = {})
      data = {}

      %i[hostname password].each { |k| data[k] = send(k) if send(k) }

      data[:wifi_config_options] = wpa_config.to_h(opts.fetch(:with_passwords, false)) if wpa_config
      data[:boot_config_options] = boot_config.to_h if boot_config
      data[:initial_setup_options] = initial_setup.to_h if initial_setup

      data
    end

    # Dumps the hash to a YAML format, taking in +opts+ to pass to to_h
    def to_yaml(opts = {})
      Psych.dump(to_h(opts))
    end
  end
end
