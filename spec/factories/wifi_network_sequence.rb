FactoryBot.define do
  sequence :wifi_networks do
    {
      "Network#{SecureRandom.hex}" => SecureRandom.hex,
      "Network#{SecureRandom.hex}" => SecureRandom.hex
    }
  end
end
