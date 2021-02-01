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

      # Takes in +opts+ for either the attributes, or a single :disk attribute to set them all
      def initialize(opts = {})
        if opts.key?(:disk)
          opts[:disk].to_h.each_pair do |k, v|
            next unless respond_to?(k)

            instance_variable_set(:"@#{k}", v)
          end
          @partitions ||= []
          @partitions.map! { |x| StorageDevice.new(disk: x) }
          @capacity = opts[:disk].size
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

      # Return a view of the path, mount status, and capacity
      def to_s
        "#{dev_path}: #{first_mounted_path || 'unmounted'} (#{capacity.bytes_h})"
      end

      # Given an image +path+, writes the image to this StorageDevice
      def write_image(path)
        `sudo dd bs=1m if=#{path} of=#{dev_path}`
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
