require 'plist'
require 'strings-case'

module PiMaker
  module DiskManagement
    # The disk protocol for Mac devices
    class MacOs < DiskProtocol
      class << self
        # Gets all attached disks, turns them into DiskProtocol::Disk objects
        def list
          dinfo = `diskutil list -plist`
          drm = `diskutil list`.split("\n\n")
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
          parse_diskinfo(`diskutil info #{dev_path}`)
        end

        # Mounts the disk +dsk+, ignoring the +_mp+ arg since Mac has
        # default mounting paths under /Volumes
        def mount_disk(dsk, _mp = nil)
          `diskutil mountDisk #{dsk}`
        end

        # Unmounts the disk at +dsk+
        def unmount_disk(dsk)
          `diskutil unmountDisk #{dsk}`
        end

        # Prepare the disk +dsk+ to be removed from the computer
        def eject_disk(dsk)
          `diskutil eject #{dsk}`
        end

        private

        # Parse returned table from diskutil info +dinfo+
        def parse_diskinfo(dinfo)
          info = dinfo.split("\n")
                      .reject(&:empty?)
                      .tap(&:shift)
                      .map { |x| /\s*(.*):\s*(.*)/.match(x) }
                      .map(&:captures)
                      .to_h

          info.transform_keys! { |x| Strings::Case.underscore(x) }
              .transform_keys!(&:to_sym)

          info.transform_values! do |x|
            if x.match?(/Bytes/)
              x.match(/(\d+) Bytes/)
               .captures
               .first
               .to_i
            else
              x
            end
          end

          info.transform_values! do |x|
            if %w[Yes No].include?(x)
              x == 'Yes'
            else
              x
            end
          end

          info
        end

        # Turns the passed plist +pl+ and path/removability matrix +fs+ to create Disks
        def dstruct(pl, fs)
          pl.map! do |entry|
            entry.merge!(
              removable: fs.find { |a, _b| entry[:dev_path].match(a) }[1]
            )

            d = DiskProtocol::Disk.new

            entry.each_pair { |k, v| d[k] = v }
            dstruct(d.partitions, fs)
            d
          end
        end

        # Converts an individual entry from the plist +pl+ into a hash of Disk options
        def parse_disk_plist_entry(pl)
          dpath = '/dev/' + pl['DeviceIdentifier']
          parts = if pl.key?('Partitions')
                    pl['Partitions'].map { |x| parse_disk_plist_entry(x) }
                  else
                    []
                  end

          {
            dev_path: dpath,
            size: pl['Size'],
            mount_point: pl['MountPoint'],
            partitions: parts,
            filesystem: mount_fs(dpath)
          }
        end

        # Takes in a string estimation of size in GB/MB and converts it to
        # single byte representation
        def byte_convert(bstr)
          sz = /(\d+(?:\.\d)) (GB|MB)/.match(bstr)

          isz = sz[1]
          scale = sz[2]

          case scale
          when 'KB'
            isz.to_f * 1000
          when 'MB'
            isz.to_f * (1000**2)
          when 'GB'
            isz.to_f * (1000**3)
          end.floor
        end
      end
    end
  end
end
