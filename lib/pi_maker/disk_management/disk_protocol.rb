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
          list.map { |dsk| DiskManagement::StorageDevice.new(disk: dsk) }
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
          unmount_disk(dsk)
          IO.popen("sudo dd bs=1m if=#{img_path} of=#{raw_disk_path(dsk)}", err: %i[child out])
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
          when p2
            mp.match(p2)[1]
          when p3
            mp.match(p3)[1]
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
