# frozen_string_literal: true

require 'thor'

module PiMaker
  module Commands
    class Wifi < Thor
      namespace :wifi

      desc 'delete [SSID]', 'Deletes a stored network from persistance'

      def delete(ssid = nil)
        if options[:help]
          invoke :help, ['delete']
        else
          require_relative 'wifi/delete'
          PiMaker::Commands::Wifi::Delete.new(ssid, options).execute
        end
      end

      desc 'supplicant', 'Write a wpa_supplicant.conf file to copy manually'

      method_option :save, aliases: '-s', type: :string,
                           desc: 'Where to save to, defaults to current directory'

      method_option :credentials, aliases: '-c', type: :hash,
                                  desc: 'Set a single credential as the file contents'

      def supplicant(*)
        if options[:help]
          invoke :help, ['supplicant']
        else
          require_relative 'wifi/supplicant'
          PiMaker::Commands::Wifi::Supplicant.new(options).execute
        end
      end

      desc 'list', 'Show stored wifi configs'

      method_option :passwords, aliases: '-p', type: :boolean,
                                desc: 'Whether to show passwords for networks'

      def list(*)
        if options[:help]
          invoke :help, ['list']
        else
          require_relative 'wifi/list'
          PiMaker::Commands::Wifi::List.new(options).execute
        end
      end

      desc 'add [SSID] [PASSWD]', 'Adds a new wifi config to the persistant store'

      def add(ssid = nil, passwd = nil)
        if options[:help]
          invoke :help, ['add']
        else
          require_relative 'wifi/add'
          PiMaker::Commands::Wifi::Add.new(ssid, passwd, options).execute
        end
      end
    end
  end
end
