FactoryBot.define do
  factory :wpa_config, class: PiMaker::WpaConfig do
    sequence(:networks) do
      {
        "Network#{SecureRandom.hex}" => SecureRandom.hex,
        "Network#{SecureRandom.hex}" => SecureRandom.hex
      }
    end

    initialize_with { PiMaker::WpaConfig.new(**attributes) }
  end
end
