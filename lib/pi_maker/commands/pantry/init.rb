# frozen_string_literal: true

require_relative '../../command'

module PiMaker
  module Commands
    class Pantry
      class Init < PiMaker::Command
        def initialize(path, options)
          @path = path
          @options = options
        end

        def run(input: $stdin, output: $stdout)
          FileUtils.mkdir_p(@path) if @path

          [@path, "#{Dir.home}/.config", Dir.home, Dir.pwd].compact.detect do |loc|
            dpath = "#{loc}/.pi_maker"

            next unless Dir.exist?(loc)

            if Dir.exist?("#{dpath}/recipes")
              write_over = @options[:overwrite] ||
                           (@options[:interactive] && prompt.yes?("Overwrite pantry in #{dpath}"))

              raise CLI::Error, 'Pantry already exists' unless write_over

              FileUtils.rm_rf(dpath)
            end

            PiMaker::Pantry.new(base_path: dpath).write
            File.open("#{Dir.home}/.pi_maker", 'w+') { |f| f << File.absolute_path(dpath) }

            prompt.ok("Wrote pantry to #{dpath}")

            true
          end || (prompt.error('No viable location found, provide a path and try again') && abort)
        end

        alias run_interactive run
      end
    end
  end
end
