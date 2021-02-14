FactoryBot.define do
  factory :pantry, class: PiMaker::Pantry do
    initialize_with { PiMaker::Pantry.new(**attributes) }
  end
end
