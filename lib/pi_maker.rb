require 'pi_maker/version'
require 'pi_maker/recipe'
require 'pi_maker/command_group'
require 'pi_maker/network_identifier'

# Easy bake Raspberry Pi
module PiMaker
  # Examines the RUBY_PLATFORM constant to determine what OS we are running on.
  # Returns one of :windows, :mac, :linux, or :raspberrypi
  class << self
    # Returns a symbol corresponding to the operating system
    def host_os
      case RUBY_PLATFORM
      when /cygwin|mswin|mingw|bccwin|wince|emx/
        :windows
      when /darwin/
        :mac
      when /linux/
        pi = File.read('/proc/cpuinfo') =~ /Raspberry Pi/
        pi ? :raspberrypi : :linux
      end
    end
  end
end
