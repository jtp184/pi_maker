FactoryBot.define do
  factory :wpa_config, class: PiMaker::WpaConfig do
    networks { generate(:wifi_networks) }

    initialize_with { PiMaker::WpaConfig.new(**attributes) }
  end
end
