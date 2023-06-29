module PiMaker
  module DiskManagement
    # Represents an attached filesystem
    class StorageDevice
      # The device path on the system in /dev/
      attr_reader :dev_path
      # Partitions present on this device
      attr_reader :partitions
      # The filesystem path to the device
      attr_reader :mount_point
      # Format of device
      attr_reader :filesystem
      # Whether this is an internal or external device
      attr_reader :removable
      # Total drive capacity reported from cl
      attr_reader :capacity

      # Mapping for byte values
      BYTE_SIZES = {
        byte: 1,
        kilobyte: 1000**1,
        megabyte: 1000**2,
        gigabyte: 1000**3,
        terrabyte: 1000**4
      }.freeze

      # Takes in +opts+ for either the attributes, or a single :disk attribute to set them all
      def initialize(opts = {})
        if opts.key?(:disk)
          opts[:disk].to_h.each_pair do |k, v|
            next unless respond_to?(k)

            instance_variable_set(:"@#{k}", v)
          end

          @partitions ||= []
          @partitions.map! { |x| StorageDevice.new(disk: x) }
          @capacity = opts[:disk].bytesize
        else
          opts.each_pair do |k, v|
            next unless respond_to?(:"#{k}=")

            instance_variable_set(:"@#{k}", v)
          end
        end
      end

      # Convert everything to hash format, including recursing the partitions
      def to_h
        h = %i[dev_path partitions mount_point filesystem removable capacity].map do |k|
          [k, send(k)]
        end.to_h

        h[:partitions] = h[:partitions].map(&:to_h)
        h
      end

      # Returns the dev path for munging
      def to_s
        dev_path
      end

      # Return a view of the path, mount status, and capacity
      def inspect
        s = +''
        s << dev_path
        s << ': '
        s << (first_mounted_path || 'unmounted')
        s << ' | '
        s << partitions.count.to_s
        s << ' partition'
        s << 's' unless partitions.count == 1
        s << " (#{size})"
      end

      # Returns a string representation with digits to +round_to+
      def size(round_to = 4)
        return '0 bytes' if capacity.zero?

        unit = BYTE_SIZES.to_a.reject { |_scalar, value| capacity < value }.last

        value_str = (capacity / unit[1].to_f).round(round_to)

        unit_str = unit[0].to_s
        unit_str << 's' unless capacity % 10 == 1

        "#{value_str} #{unit_str}"
      end

      # Gets the partition which is largest by capacity
      def largest_partition
        partitions.max { |a, b| a.capacity <=> b.capacity }
      end

      # Predicate method to return true if first_mounted exists
      def mounted?
        !!first_mounted
      end

      # Returns the mount point, or partition mount point
      def first_mounted
        return self if mount_point

        partitions.find(&:mount_point)
      end

      # Returns this mounted path if there is one, otherwise finds the first mounted partition
      def first_mounted_path
        first_mounted&.mount_point
      end

      # Get a raw disk path for the disk
      def raw_disk_path
        DiskManagement.raw_disk_path(self)
      end

      # Given an image +img_path+, writes the image to the disk of this StorageDevice
      def write_image(img_path)
        DiskManagement.write_image(img_path, self)
      end

      # Mounts the device if it isn't already
      def mount
        return first_mounted_path if first_mounted_path

        prt = largest_partition
        DiskManagement.mount_disk(prt.dev_path, dev_path)
      end

      # Unmounts this device if mounted
      def unmount
        return nil unless first_mounted

        DiskManagement.unmount_disk(first_mounted.dev_path)
      end

      # Ejects this device if mounted
      def eject
        DiskManagement.eject_disk(dev_path)
      end
    end
  end
end
