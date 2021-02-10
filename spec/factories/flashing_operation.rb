FactoryBot.define do
  factory :flashing_operation, class: PiMaker::DiskManagement::FlashingOperation do
    image_path { 'image_file.img' }
    disk { FactoryBot.build(:storage_device) }

    initialize_with { PiMaker::DiskManagement::FlashingOperation.new(**attributes) }
  end
end
