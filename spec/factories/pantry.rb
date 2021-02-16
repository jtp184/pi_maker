FactoryBot.define do
  factory :pantry, class: PiMaker::Pantry do
    recipes { [build(:recipe)] }
    wifi_networks { generate(:wifi_networks) }

    factory :secure_pantry do
      password { SecureRandom.hex }
    end

    initialize_with { PiMaker::Pantry.new(**attributes) }
  end
end
