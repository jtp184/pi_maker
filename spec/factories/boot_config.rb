FactoryBot.define do
  factory :boot_config, class: PiMaker::BootConfig do
    initialize_with { PiMaker::BootConfig.new(**attributes) }
  end
end
