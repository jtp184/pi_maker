FactoryBot.define do
  factory :pantry, class: PiMaker::Pantry do
    recipes { [build(:recipe)] }
    wifi_networks { generate(:wifi_networks) }

    initialize_with { PiMaker::Pantry.new(**attributes) }
  end
end
