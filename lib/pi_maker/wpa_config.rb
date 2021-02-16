require 'forwardable'

module PiMaker
  # Captures multiple wifi network setups and the country code, generates the
  # file via its to_s method
  class WpaConfig
    extend Forwardable
    # The array of networks this config shares
    attr_accessor :networks
    # The country code provided by the user
    attr_accessor :country_code

    def_delegators :@networks, :count

    # How to output a network into string format
    NETWORK_FORMATTER = <<~DOC.freeze
      network={
        ssid="%<ssid>s"
        psk="%<password>s"
        priority=%<priority>d
      }
    DOC

    # Two opening lines present in a wpa_config
    PREAMBLE = "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev\nupdate_config=1\n".freeze

    FILENAME = 'wpa_supplicant.conf'.freeze

    # Parse the +yml+ string and create a new instance from it
    def self.from_yaml(yml, encrypted = nil)
      new(Psych.load(FileEncrypter.decrypt(yml, encrypted)))
    end

    # Take in +opts+ for networks and country_code
    def initialize(opts = {})
      @networks = opts.fetch(:networks, {})
      @country_code = opts.fetch(:country_code, 'US')
    end

    # Given a new +id+ and +passwd+, adds a new credential
    def append(id, passwd)
      networks[id] = passwd
      self
    end

    # Returns true if we have an entry for +id+
    def ssid?(id)
      networks.key?(id)
    end

    # Runs the build method and returns the result
    def to_s
      build
    end

    alias to_str to_s

    # Returns a hash representation, optionally +with_passwords+
    def to_h(with_passwords = false)
      {
        country_code: country_code,
        networks: with_passwords ? networks : networks.keys
      }
    end

    # Export a YAML representation of the class
    def to_yaml(password = nil)
      yml = Psych.dump(to_h)

      FileEncrypter.encrypt(yml, password)
    end

    private

    # Adds together the preamble and country code to the networks to make the
    # completed file contents string
    def build
      "#{PREAMBLE}country=#{country_code}\n\n" + networks.map.with_index do |n, x|
        format(NETWORK_FORMATTER, ssid: n[0], password: n[1], priority: x + 1)
      end.join("\n\n")
    end
  end
end
