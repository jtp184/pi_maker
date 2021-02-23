# frozen_string_literal: true

require 'thor'

module PiMaker
  module Commands
    class Boot < Thor
      namespace :boot

      desc 'flash', 'Flash a card from an image'

      method_option :image, aliases: '-m', type: :string,
                            desc: 'An image file to write'

      method_option :device, aliases: '-d', type: :string,
                             desc: 'The device to write to'

      def flash(*)
        if options[:help]
          invoke :help, ['flash']
        else
          require_relative 'boot/flash'
          PiMaker::Commands::Boot::Flash.new(options).execute
        end
      end

      desc 'config', 'Set values on the config file directly'

      method_option :values, aliases: '-v', type: :hash,
                             desc: 'Pass values to the config'

      def config(*)
        if options[:help]
          invoke :help, ['config']
        else
          require_relative 'boot/config'
          PiMaker::Commands::Boot::Config.new(options).execute
        end
      end
    end
  end
end
