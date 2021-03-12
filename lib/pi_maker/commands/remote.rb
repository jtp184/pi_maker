# frozen_string_literal: true

require 'thor'

module PiMaker
  module Commands
    class Remote < Thor
      namespace :remote

      desc 'apply', ''

      def apply(reference = nil)
        if options[:help]
          invoke :help, ['apply']
        else
          require_relative 'remote/apply'
          PiMaker::Commands::Remote::Apply.new(reference, options).execute
        end
      end

      desc 'upload', 'Transfer a local file to the remote'

      def upload(local_file = nil, remote_file = nil)
        if options[:help]
          invoke :help, ['upload']
        else
          require_relative 'remote/upload'
          PiMaker::Commands::Remote::Upload.new(local_file, remote_file, options).execute
        end
      end

      desc 'download', 'Copy a remote file'

      def download(remote_file = nil, local_file = nil)
        if options[:help]
          invoke :help, ['download']
        else
          require_relative 'remote/download'
          PiMaker::Commands::Remote::Download.new(local_file, remote_file, options).execute
        end
      end

      desc 'connect', 'Connect to a pi over SSH'
      method_option :scan, aliases: '-s', type: :boolean, default: false,
                           desc: 'Perform a network scan to find hosts'
      method_option :connect_with, aliases: '-c', type: :string, default: 'i',
                                   desc: 'Whether to use scanned [i]p_address or [h]ostname to connect'

      def connect(reference = nil)
        if options[:help]
          invoke :help, ['connect']
        else
          require_relative 'remote/connect'
          PiMaker::Commands::Remote::Connect.new(reference, options).execute
        end
      end
    end
  end
end
