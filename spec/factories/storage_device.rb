FactoryBot.define do
  factory :storage_device, aliases: [:disk], class: PiMaker::DiskManagement::StorageDevice do
    dev_path { '/dev/diskT' }
    partitions { [] }
    removable { true }
    capacity { 640_000 }

    initialize_with do
      f = PiMaker::DiskManagement::StorageDevice.new
      attributes.each { |k, v| f.instance_variable_set(:"@#{k}", v) }
      f
    end
  end
end
