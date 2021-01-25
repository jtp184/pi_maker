module PiMaker
  # Captures multiple wifi network setups and the country code, generates the
  # file via its to_s method
  class WifiConfig
    # Stores the Wifi Credentials the user passes in
    WifiCredentials = Struct.new(:ssid, :password, :priority) do
      def to_s
        %(network={\n  ssid="#{ssid}"\n  psk="#{password}"\n  priority=#{priority}\n})
      end
    end

    # The array of networks this config shares
    attr_accessor :networks
    # The country code provided by the user
    attr_accessor :country_code

    # Take in +opts+ for networks and country_code
    def initialize(opts = {})
      @networks = opts.fetch(:networks, [])
      @country_code = opts.fetch(:country_code, 'US')
    end

    # Runs the build method and returns the result
    def to_s
      build
    end

    # Adds a priority based on index to the networks
    def prioritize_networks
      networks.each_with_index { |n, i| n.priority = i + 1 }
      self
    end

    private

    # Adds together the preamble and country code to the networks to make the
    # completed file contents string
    def build
      str = +''
      str += preamble.join("\n")
      str += "\n"
      str += "country=#{country_code}"
      str += "\n"
      str += "\n"
      str + networks.map(&:to_s).join("\n\n")
    end

    # Two opening lines present in a wpa_config
    def preamble
      [
        'ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev',
        'update_config=1'
      ]
    end
  end
end
