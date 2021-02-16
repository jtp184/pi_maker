FactoryBot.define do
  factory :recipe, class: PiMaker::Recipe do
    hostname { "Raspi-#{SecureRandom.hex}" }
    password { SecureRandom.hex }
    wpa_config
    boot_config
    association :initial_setup, factory: :ingredients

    initialize_with { PiMaker::Recipe.new(**attributes) }
  end
end
