FactoryBot.define do
  factory :command_group, class: PiMaker::CommandGroup do
    instructions

    initialize_with { PiMaker::CommandGroup.new(**attributes) }
  end
end
