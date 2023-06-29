require 'forwardable'

module PiMaker
  module DiskManagement
    # Abstract class for acquiring disks and disk information.
    class DiskProtocol
      # A connected disk and its information
      Disk = Struct.new(:dev_path, :mount_point, :removable, :partitions, :bytesize, :filesystem)

      class << self
        # Converts listed disks into StorageDevice objects
        def list_devices
          list_blocks.map { |dsk| DiskManagement::StorageDevice.new(disk: dsk) }
        end

        # Returns the device which matches the mount path defined in PiMaker.sd_card_path
        def sd_card_device
          list_devices.detect { |dsk| dsk.first_mounted_path == PiMaker.sd_card_path }
        end

        # Gets the size of the entire directory using `du`
        def dir_size(path)
          PiMaker.system_cmd(command: ['du -sk', path])
                 .split(/\t/)
                 .first
                 .to_i
                 .*(1000)
        end

        # Given an image +img_path+, writes the image to the disk +dsk+
        def write_image(img_path, dsk)
          unmount_disk(dsk) if dsk.is_a?(StorageDevice) && dsk.mounted?
          FlashingOperation.start(image_path: img_path, disk: dsk)
        end

        # Scans the mount_list result for +dev_path+ and returns the path if it is mounted
        def mount_point_for(dev_path)
          p1 = /#{Regexp.escape(dev_path)}\b/
          p2 = /type \w+\s/

          mp = mount_list.find { |x| x =~ p1 }
          return nil if mp.nil?

          mp.gsub(p2, '')
            .split(/\s\(/)
            .[](0)
            .split(/\son\s/)
            .last
        end

        # Scans the mount_list result for +dev_path+ and returns the filesystem type
        def mount_fs(dev_path)
          p1 = /#{Regexp.escape(dev_path)}\b/
          p2 = /type (\w+)\s/
          p3 = /\((\w+), /

          mp = mount_list.find { |x| x =~ p1 }
          return nil if mp.nil?

          case mp
          when p2 then mp.match(p2)[1]
          when p3 then mp.match(p3)[1]
          end
        end

        # True if a mount_list result is found for +dev_path+
        def mounted?(dev_path)
          !!mount_list.find { |x| x =~ /#{Regexp.escape(dev_path)}\b/ }
        end

        private

        # Uses the system mount command to identify mounted devices
        def mount_list
          PiMaker.system_cmd('mount').split("\n")
        end
      end
    end
  end
end
