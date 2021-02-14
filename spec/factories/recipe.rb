FactoryBot.define do
  factory :recipe, class: PiMaker::Recipe do
    initialize_with { PiMaker::Recipe.new(**attributes) }
  end
end
