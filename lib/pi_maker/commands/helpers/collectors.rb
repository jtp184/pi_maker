require 'tempfile'

module PiMaker
  module Commands
    module Helpers
      # Helper module for collecting user input
      module Collectors
        private

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

        def collect_ingredients
          prompt.warn('Collecting ingredients')

          list_args = {}
          text_args = {}

          catch :user_finish do
            PiMaker::Ingredients::LISTS.each do |list_inputs|
              list_name, list_type = list_inputs
              list_args[list_name] = if list_type == Array
                                       ingredient_option_prompt(list_name)
                                     elsif list_type == Hash
                                       keys = ingredient_option_prompt(list_name)
                                       vals = keys.map do |ky|
                                         ingredient_option_prompt("#{list_name}[#{ky}]")
                                       end

                                       keys.zip(vals).to_h
                                     end
            end

            PiMaker::Ingredients::TEXT_BLOCKS.each do |block_name, block_path|
              text_args[block_name] = ingredient_option_prompt(block_path)
            end
          end

          PiMaker::Ingredients.new(list_args.merge(text_args))
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

        def ingredient_option_prompt(title)
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
end
