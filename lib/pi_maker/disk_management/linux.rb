require 'json'
require 'fileutils'

module PiMaker
  module DiskManagement
    # The disk protocol class for linux systems like Raspi
    class Linux < DiskProtocol
      class << self
        # Gets all attached disks, turns them into DiskProtocol::Disk objects, and returns
        def list_blocks
          cmd = PiMaker.system_cmd('lsblk -Jbo NAME,PATH,SIZE,MOUNTPOINT,FSTYPE,RM')

          JSON.parse(cmd)['blockdevices']
              .map { |di| dstruct(di) }
        end

        # Gets maximal info for disk at +dev_path+ from lsblk
        def disk_info(dev_path)
          cmd = PiMaker.system_cmd("lsblk #{dev_path} -Jbo NAME,PATH,SIZE,MOUNTPOINT,FSTYPE,RM")
          data = JSON.parse(cmd)['blockdevices'].first

          dstruct(data)
        end

        # Uses the mount command to mount disk +dsk+, with mount point +mp+
        def mount_disk(dsk, mountp = nil)
          mtp = mountp.nil? ? dsk : mountp

          FileUtils.mkdir_p(mtp)
          PiMaker.system_cmd(command: ["sudo mount #{dsk}", mtp])
        end

        # Unmounts the disk at path +dsk+
        def unmount_disk(dsk)
          PiMaker.system_cmd("sudo umount #{dsk}")
        end

        # Prepare the disk +dsk+ to be removed from the computer
        def eject_disk(dsk)
          unmount_disk(dsk)
        end

        # Same dev and raw path on linux
        def raw_disk_path(dsk)
          dsk.dev_path
        end

        private

        # Takes in a +subhsh+ from lksblk's json result and turns it into a DiskProtocol::Disk
        def dstruct(subhsh)
          md = {
            dev_path: subhsh['path'],
            removable: subhsh['rm'],
            bytesize: subhsh['size'],
            mount_point: subhsh['mountpoint'],
            filesystem: subhsh['fstype']
          }

          if subhsh.key?('children')
            chi = subhsh['children'].map { |b| dstruct(b) }
            md.merge!(partitions: chi)
          end

          DiskProtocol::Disk.new.tap do |d|
            md.each_pair { |k, v| d[k] = v }
          end
        end
      end
    end
  end
end
