require 'pi_maker/disk_management/storage_device'
require 'pi_maker/disk_management/disk_protocol'
require 'pi_maker/disk_management/mac_os'
require 'pi_maker/disk_management/linux'

module PiMaker
  # Encloses functionality to manage connected devices
  module DiskManagement
    class << self
      # Pass any calls through to the protocol object
      def method_missing(mtd_name, *args)
        super unless protocol.respond_to?(mtd_name)
        protocol.public_send(mtd_name, *args)
      end

      # Returns true if the selected protocol responds to +mtd+ as well
      def respond_to?(mtd)
        protocol.respond_to?(mtd) || super
      end

      # Returns the platform specific DiskProtocol in use
      def protocol
        case PiMaker.host_os
        when :linux, :raspberrypi
          DiskManagement::Linux
        when :mac
          DiskManagement::MacOs
        end
      end
    end
  end
end
