# frozen_string_literal: true

require_relative '../../command'
require_relative '../helpers'

module PiMaker
  module Commands
    class Remote
      class Upload < PiMaker::Command
        include Helpers

        def initialize(local_file, remote_file, options)
          @local_file = File.absolute_path(local_file)
          @remote_file = remote_file

          raise CLI::Error, 'Missing file options' unless @local_file && @remote_file

          @options = options
        end

        def run(input: $stdin, output: $stdout)
          conf = parse_connection_config ||
                 (@options[:scan] && scan_for_host) ||
                 (@options[:interactive] && collect_connection_options)

          raise CLI::Error, 'No connection options given' unless conf

          @conf = PiMaker.default_login.merge(conf)

          runner.call

          prompt.ok("Uploaded #{File.basename(@local_file)} to #{remote_reference}")
        end

        alias run_interactive run

        private

        def remote_reference
          "#{@conf[:user]}@#{@conf[:hostname]}:#{@remote_file}"
        end

        def runner
          PiMaker::RemoteRunner.new(
            config: @conf,
            upload_files: [[@local_file, @remote_file]]
          )
        end
      end
    end
  end
end
