# frozen_string_literal: true

require_relative '../../command'

module PiMaker
  module Commands
    class Recipe
      class Initial < PiMaker::Command
        def initialize(hostname, options)
          @hostname = hostname
          @options = options
        end

        def run(input: $stdin, output: $stdout)
          credentials[:hostname] = if @options[:credentials]
                                     oc = @options[:credentials]
                                     oc[:hostname] || oc['hostname']
                                   elsif @options[:scan] || @options[:interactive]
                                     scan_for_host
                                   else
                                     raise CLI::Error, 'No hostname to connect with'
                                   end

          initial_config

          if @options[:interactive] && !@options[:verbose]
            spinbar.run { perform_initial }
          else
            perform_initial
          end

          prompt.ok('Commands run')
        end

        alias run_interactive run

        private

        def perform_initial
          perform_basic
          perform_login
          perform_reboot
        end

        def scan_for_host
          args = {}
          args[:scan_with] = @options[:scan_with] if @options[:scan_with]

          results = PiMaker::NetworkIdentifier.call(args)

          return nil if results.empty?
          return results.first if results.one?

          unless @options[:interactive]
            raise CLI::Error, "Multiple ips, please pass one as an argument:\n#{results.join("\n")}"
          end

          prompt.select('Which IP?', results)
        end

        def perform_reboot
          return unless @options[:reboot]

          if @options[:verbose]
            runner({ shell: ['sudo reboot now'] }).call do |l|
              prompt.say(pastel.bright_black(l))
            end
          else
            runner({ shell: ['sudo reboot now'] }).call
          end
        end

        def perform_login
          return unless @options[:login]

          if @options[:verbose]
            runner(recipe.login_setup).call do |l|
              prompt.say(pastel.bright_black(l))
            end
          else
            runner(recipe.login_setup).call
          end
        end

        def perform_basic
          if @options[:verbose]
            runner.call do |l|
              prompt.say(pastel.bright_black(l))
            end
          else
            runner.call
          end
        end

        def runner(cmds = initial_config)
          @runner = PiMaker::RemoteRunner.new(
            config: credentials || {},
            command_group: PiMaker::CommandGroup.new(cmds)
          )
        end

        def credentials
          @credentials ||= (@options[:credentials] || {})
        end

        def recipe
          return @recipe if @recipe

          pantry = PiMaker::Pantry.global

          @recipe = begin
            recipe = pantry.recipes.find { |r| r.hostname == @hostname }

            if @options[:interactive]
              recipes = pantry.recipes.map { |r| [r.hostname, r] }.to_h
              recipe || recipes[prompt.select('Use which recipe?', recipes.keys)]
            else
              raise CLI::Error, 'No recipe' unless recipe

              recipe
            end
          end
        end

        def initial_config
          @initial_config ||= recipe.initial_setup
        end

        def spinbar
          spinner(
            '[:spinner] Applying initial config...',
            success_mark: '✅',
            error_mark: '❗️',
            frames: '🕒🕓🕔🕕🕖🕗🕘🕙🕚🕛🕐🕑',
            interval: 12
          )
        end
      end
    end
  end
end
