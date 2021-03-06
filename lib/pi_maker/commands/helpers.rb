require 'tempfile'

module PiMaker
  module Commands
    # Helper functions for repeated actions like user input
    module Helpers
      private

      def parse_connection_reference
        return nil unless @reference

        str_conf = [
          /(?<user>\w+)@(?<hostname>[\d.]+)\[(?<password>[^\s]+)\]/,
          /(?<user>\w+)@(?<hostname>[\d.]+)/,
          /(?<hostname>[\d.]+)/
        ].detect { |r| r =~ @reference }

        if str_conf
          str_conf.match(@reference).named_captures.transform_keys(&:to_sym)
        else
          rc = PiMaker::Pantry.global.recipes.detect { |r| r.hostname == @reference }
          return nil unless rc

          rc.to_h
            .slice(:hostname, :password)
            .map { |k, v| k == :hostname ? [k, "#{v}.local"] : [k, v] }
            .to_h
        end
      end

      def sudo_request
        prompt.error('Acquiring sudo') if @options[:interactive]
        PiMaker.system_cmd('sudo echo')
      end

      def collect_connection_options
        prompt.warn('Collecting connection config')

        {
          user: prompt.ask('user', default: 'pi'),
          hostname: prompt.ask('hostname', default: 'raspberrypi.local'),
          password: prompt.ask('password', default: 'raspberry')
        }
      end

      def collect_wifi_networks
        wpa = PiMaker::WpaConfig.new
        prompt.warn('Collecting wifi networks')

        loop do
          ssid = prompt.ask('SSID: ')
          passwd = PiMaker::Pantry.global.wifi_networks[ssid] || prompt.mask('Password: ')

          wpa.append(ssid, passwd)
          break unless prompt.yes?('Add more networks?')
        end

        wpa
      end

      def collect_boot_options
        prompt.warn('Collecting boot options')

        boot = PiMaker::BootConfig.new(
          ssh: @ssh || prompt.yes?('Enable SSH at boot? ')
        )

        PiMaker::BootConfig::FILTERS.each do |bf|
          prompt.say("Group [#{bf}]\n")
          prompt.ok(Psych.dump(boot.config[bf].to_h))

          case boot_option_prompt
          when :finish
            break
          when :clear
            boot[bf] = OpenStruct.new
          when :edit
            boot[bf] = OpenStruct.new(Psych.load(editor_text(Psych.dump(boot.config[bf].to_h))))
          end

          prompt.ok(Psych.dump(boot.config[bf].to_h))
        end

        boot
      end

      def collect_instructions
        prompt.warn('Collecting instructions')

        list_args = {}
        text_args = {}

        catch :user_finish do
          PiMaker::Instructions::LISTS.each do |list_inputs|
            list_name, list_type = list_inputs
            list_args[list_name] = if list_type == Array
                                     instruction_option_prompt(list_name)
                                   elsif list_type == Hash
                                     keys = instruction_option_prompt(list_name)
                                     vals = keys.map do |ky|
                                       instruction_option_prompt("#{list_name}[#{ky}]")
                                     end

                                     keys.zip(vals).to_h
                                   end
          end

          PiMaker::Instructions::TEXT_BLOCKS.each do |block_name, block_path|
            text_args[block_name] = instruction_option_prompt(block_path)
          end
        end

        PiMaker::Instructions.new(list_args.merge(text_args))
      end

      def choose_disk
        prompt.warn('Choosing disk')

        if PiMaker::DiskManagement.sd_card_device
          d_prompt = "Use #{pastel.cyan(PiMaker::DiskManagement.sd_card_device.inspect)}?"
          default = prompt.yes?(d_prompt)

          return PiMaker::DiskManagement.sd_card_device if default
        end

        choices = PiMaker::DiskManagement.list_devices.map do |d|
          [d.inspect, d]
        end.to_h

        disk_choice = prompt.select('Use which disk?', choices.keys.map { |c| pastel.cyan(c) })
        choices[pastel.strip(disk_choice)]
      end

      def boot_option_prompt
        prompt.expand(
          'Modify?',
          { key: 'c', name: 'clear', value: :clear },
          { key: 'e', name: 'edit', value: :edit },
          { key: 'f', name: 'finish', value: :finish },
          { key: 'n', name: 'next', value: :next },
          { key: '?', name: 'END', value: nil }
        )
      end

      def instruction_option_prompt(title)
        action = prompt.expand(
          "Modify options for #{pastel.blue(title)}?",
          { key: 'y', name: 'enter on one line', value: :one },
          { key: 'e', name: 'edit in editor', value: :edit },
          { key: 'n', name: 'next', value: :next },
          { key: 'f', name: 'finish', value: :finish },
          { key: '?', name: 'END', value: nil }
        )

        case action
        when :one
          prompt.ask("Items for #{title}: ").scan(%r{[/\w_-]+})
        when :edit
          editor_text.split("\n")
        when :next
          []
        when :finish
          throw :user_finish
        end
      end
    end
  end
end
