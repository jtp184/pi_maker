FactoryBot.define do
  factory :recipe, class: PiMaker::Recipe do
    hostname { "Raspi-#{SecureRandom.hex}" }
    password { SecureRandom.hex }
    wpa_config
    boot_config
    association :initial_setup, factory: :instructions
    additional_setup { { rehash: PiMaker::Instructions.new(shell: 'rbenv rehash') } }

    initialize_with { PiMaker::Recipe.new(**attributes) }
  end
end
