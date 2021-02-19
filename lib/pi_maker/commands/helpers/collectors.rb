require 'tempfile'

module PiMaker
  module Commands
    module Helpers
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

          boot = PiMaker::BootConfig.new(ssh: prompt.yes?('Enable SSH at boot? '))

          PiMaker::BootConfig::FILTERS.each do |bf|
            prompt.say("Group [#{bf}]\n")
            prompt.ok(Psych.dump(boot.config[bf].to_h))

            action = prompt.expand(
              'Modify?',
              { key: 'c', name: 'clear', value: :clear },
              { key: 'e', name: 'edit', value: :edit },
              { key: 'f', name: 'finish', value: :finish },
              { key: 'n', name: 'next', value: :next }
            )

            case action
            when :clear
              boot[bf] = OpenStruct.new
            when :edit
              boot[bf] = OpenStruct.new(
                Psych.load(
                  editor_text(Psych.dump(boot.config[bf].to_h))
                )
              )
            when :finish
              break
            end

            prompt.ok(Psych.dump(boot.config[bf].to_h))
          end

          boot
        end
      end
    end
  end
end
