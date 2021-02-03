require 'net/ssh'
require 'net/scp'

module PiMaker
  # Runs commands on a remote device
  class RemoteRunner
    attr_reader :config, :command_group, :result

    # Uses +opts+ to set the config and command group
    def initialize(opts = {})
      @config = {
        user: 'pi',
        hostname: 'raspberrypi.local',
        password: 'raspberry'
      }.merge(opts.fetch(:config, {}))

      @command_group = opts.fetch(:command_group, CommandGroup.new)
      @result = []
    end

    # Clears the result array, then runs run_commands and run_text_blocks
    def call
      @result = []
      run_commands
      run_text_blocks

      result
    end

    # For each command in the CommandGroup, ssh into the remote and run the command
    def run_commands
      return if command_group.commands.empty?

      command_group.commands.each do |cmd|
        @result << [cmd, []]

        Net::SSH.start(*ssh_options) do |connection|
          connection.open_channel do |ssh|
            ssh.exec(cmd) do |tty, _ret|
              tty.on_data do |_c, line|
                @result.last.last << line
              end

              tty.on_extended_data do |_c, _t, line|
                @result.last.last << line
              end
            end
          end.wait
        end

        @result.last.last << '' if @result.last.last.empty?
      end
    end

    # Creates a temp folder, then for each text_block in the CommandGroup, creates a tempfile
    # for it, then appends that tempfile to its target destination and destroys the folder
    def run_text_blocks
      return if command_group.text_blocks.empty?

      timestamp = Time.now.to_i

      temp_files = command_group.text_blocks
                                .transform_values { |_v| SecureRandom.hex }

      append_opts = timestamp, temp_files

      create_temp_folder(append_opts)
      create_temp_files(append_opts)
      append_files(append_opts)
      destroy_temp_folder(append_opts)
    end

    private

    # Given a timestamp and tempname hash +append_opts+, writes the text_block lines out to it
    def create_temp_files(append_opts)
      command_group.text_blocks.each do |filepath, lines|
        contents = StringIO.new(lines.join("\n") << "\n")
        remote = "/tmp/pi_maker_#{append_opts[0]}/#{append_opts[1][filepath]}"

        Net::SCP.upload!(
          *scp_options(
            contents,
            remote
          )
        )

        @result << ["scp #{remote}", ['']]
      end
    end

    # Given a timestamp and tempname hash +append_opts+, appends the contents of the tempfiles
    def append_files(append_opts)
      command_group.text_blocks.each do |filepath, _l|
        Net::SSH.start(*ssh_options) do |connection|
          connection.open_channel do |ssh|
            src_path = "/tmp/pi_maker_#{append_opts[0]}/#{append_opts[1][filepath]}"
            cmd = "cat #{src_path} >> #{filepath}"

            ssh.exec(cmd)
            @result << [cmd, ['']]
          end
        end
      end
    end

    # Given a timestamp as the first +append_opts+, creates the temp folder in /tmp/
    def create_temp_folder(append_opts)
      Net::SSH.start(*ssh_options) { |ssh| ssh.exec("mkdir /tmp/pi_maker_#{append_opts[0]}") }
    end

    # Given a timestamp as the first +append_opts+, destroys the temp folder in /tmp/
    def destroy_temp_folder(append_opts)
      Net::SSH.start(*ssh_options) { |ssh| ssh.exec("rm -rf /tmp/pi_maker_#{append_opts[0]}") }
    end

    # Arguments for an SSH invocation
    def ssh_options
      opts = %i[hostname user].map { |i| config[i] }
      opts << { password: config[:password] } if config[:password]

      opts
    end

    # Arguments for an SCP invocation
    def scp_options(local, remote)
      opts = %i[hostname user].map { |i| config[i] }

      opts << local
      opts << remote

      opts << { ssh: { password: config[:password] } } if config[:password]

      opts
    end
  end
end
