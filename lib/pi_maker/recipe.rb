module PiMaker
  # Define a pi and its dependencies and config options
  class Recipe
    # A hostname to set instead of raspberrypi
    attr_accessor :hostname
    # A password to set instead of raspberry
    attr_accessor :password
    # A WifiConfig to install on the card
    attr_accessor :wifi_config
    # A BootConfig to install on the card
    attr_accessor :boot_config
    # An Ingredients to set install options
    attr_accessor :initial_setup

    # Takes in +opts+ for the attributes
    def initialize(opts = {})
      @hostname =  opts.fetch(:hostname, nil)
      @password =  opts.fetch(:password, nil)
      @wifi_config =  opts.fetch(:wifi_config, WifiConfig.new)
      @boot_config =  opts.fetch(:boot_config, BootConfig.new)
      @initial_setup = opts.fetch(:initial_setup, Ingredients.new)
    end

    def self.from_yaml(yml)
      yaml = Psych.load(yml)

      inst = new(yaml.slice(:hostname, :password))

      # TODO Wifi

      inst.yaml[:boot_config_options].each do |key, value|
        boot_config.public_send(:"#{key}=", value)
      end

      inst.initial_setup = Ingredients.new(yaml[:initial_setup])

      inst
    end

    def to_yaml
    end

    private
  end
end
