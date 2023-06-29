require 'pi_maker/disk_management/storage_device'
require 'pi_maker/disk_management/flashing_operation'
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

      # Respond to protocol messages
      def respond_to_missing?(mtd, priv = false)
        protocol.respond_to?(mtd, priv) || super
      end

      # Returns the platform specific DiskProtocol in use
      def protocol
        case PiMaker.host_os
        when :linux, :raspberrypi then DiskManagement::Linux
        when :mac then DiskManagement::MacOs
        end
      end
    end
  end
end
