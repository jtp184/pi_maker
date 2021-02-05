require 'plist'
require 'strings-case'

module PiMaker
  module DiskManagement
    # The disk protocol for Mac devices
    class MacOs < DiskProtocol
      class << self
        # Gets all attached disks, turns them into DiskProtocol::Disk objects
        def list
          dinfo = PiMaker.system_cmd('diskutil list -plist')
          drm = PiMaker.system_cmd('diskutil list').split("\n\n")
                       .map(&:lines)
                       .map(&:first)
                       .map { |x| x.split(' (') }
                       .map { |a, b| [Regexp.new(Regexp.escape(a)), b.match?(/external/)] }

          adp = Plist.parse_xml(dinfo)['AllDisksAndPartitions']
          adp.map! { |x| parse_disk_plist_entry(x) }

          dstruct(adp, drm)
        end

        # Gets maximal info for disk at +dev_path+ using diskutil info
        def disk_info(dev_path)
          parse_diskinfo(PiMaker.system_cmd("diskutil info #{dev_path}"))
        end

        # Mounts the disk +dsk+, ignoring the +_mp+ arg since Mac has
        # default mounting paths under /Volumes
        def mount_disk(dsk, _mountp = nil)
          PiMaker.system_cmd("diskutil mountDisk #{dsk}")
        end

        # Unmounts the disk at +dsk+
        def unmount_disk(dsk)
          PiMaker.system_cmd("diskutil unmountDisk #{dsk}")
        end

        # Prepare the disk +dsk+ to be removed from the computer
        def eject_disk(dsk)
          PiMaker.system_cmd("diskutil eject #{dsk}")
        end

        private

        # Prepends the +dev_path+ with 'r'
        def raw_disk_path(dsk)
          dsk.to_s
             .split('/')
             .tap { |a| a[2] = "r#{a[2]}" }
             .join('/')
        end

        # Parse returned table from diskutil info +dinfo+
        def parse_diskinfo(dinfo)
          info = dinfo.split("\n")
                      .reject(&:empty?)
                      .tap(&:shift)
                      .map { |x| /\s*(.*):\s*(.*)/.match(x) }
                      .map(&:captures)
                      .to_h

          transform_diskinfo(info)
        end

        # Applies transformations to diskinfo
        def transform_diskinfo(dinfo)
          dinfo.transform_keys! { |x| Strings::Case.underscore(x) }
               .transform_keys!(&:to_sym)

          dinfo.transform_values! do |x|
            next x unless x.match?(/Bytes/)

            x.match(/(\d+) Bytes/)
             .captures
             .first
             .to_i
          end

          dinfo.transform_values! do |x|
            next x unless %w[Yes No].include?(x)

            x == 'Yes'
          end
        end

        # Turns the passed plist +pl+ and path/removability matrix +pathset+ to create Disks
        def dstruct(plist, pathset)
          plist.map! do |entry|
            entry.merge!(
              removable: pathset.find { |a, _b| entry[:dev_path].match(a) }[1]
            )

            d = DiskProtocol::Disk.new

            entry.each_pair { |k, v| d[k] = v }
            dstruct(d.partitions, pathset)
            d
          end
        end

        # Converts an individual entry from the plist +pl+ into a hash of Disk options
        def parse_disk_plist_entry(plist)
          dpath = "/dev/#{plist['DeviceIdentifier']}"
          parts = if plist.key?('Partitions')
                    plist['Partitions'].map { |x| parse_disk_plist_entry(x) }
                  else
                    []
                  end

          {
            dev_path: dpath,
            size: plist['Size'],
            mount_point: plist['MountPoint'],
            partitions: parts,
            filesystem: mount_fs(dpath)
          }
        end

        # Takes in a string estimation of size in GB/MB and converts it to
        # single byte representation
        def byte_convert(bstr)
          sz = /(\d+(?:\.\d)) (\w)B/.match(bstr)

          isz = sz[1].to_f

          factor = StorageDevice::BYTE_SIZES.detect do |k, _v|
            k.to_s.chars.first.upcase == sz[2]
          end.last

          (isz * factor).floor
        end
      end
    end
  end
end
