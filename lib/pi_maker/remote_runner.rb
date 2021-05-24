require 'net/ssh'
require 'net/scp'

module PiMaker
  # Runs commands on a remote device
  class RemoteRunner
    # The SSH options
    attr_reader :config
    # The commands to run, as a CommandGroup
    attr_reader :command_group
    # An array which is populated by the command output after running
    attr_reader :result
    # Tuples of files to copy from local to remote
    attr_reader :upload_files
    # Tuples of files to copy from remote to local
    attr_reader :download_files

    # Uses +opts+ to set the config and command group
    def initialize(opts = {})
      @config = PiMaker.default_login.merge(opts.fetch(:config, {}))

      @command_group = opts[:command_group]
      @upload_files = opts.fetch(:upload_files, [])
      @download_files = opts.fetch(:download_files, [])
      @result = []
    end

    # Clears the result array, then runs run_commands and run_text_blocks
    def call(&watcher)
      @result = []
      run_commands(&watcher)
      run_text_blocks(&watcher)
      copy_files(&watcher)

      result
    end

    # For each command in the CommandGroup, ssh into the remote and run the command
    def run_commands(&watcher)
      return unless command_group
      return if command_group.commands.empty?

      Net::SSH.start(*ssh_options) do |connection|
        command_group.commands.each do |cmd|
          @result << [cmd, []]
          watcher.call(cmd) if block_given?

          connection.open_channel do |ssh|
            ssh.exec(cmd) do |tty, _ret|
              tty.on_data do |_c, line|
                @result.last.last << line
              end

              tty.on_extended_data do |_c, _t, line|
                @result.last.last << line
              end

              watcher.call(@result.last.last.last) if block_given?
            end
          end.wait

          @result.last.last << '' if @result.last.last.empty?
        end
      end
    end

    # Creates a temp folder, then for each text_block in the CommandGroup, creates a tempfile
    # for it, then appends that tempfile to its target destination and destroys the folder
    def run_text_blocks(&watcher)
      return unless command_group
      return if command_group.text_blocks.empty?

      timestamp = Time.now.to_i

      temp_files = command_group.text_blocks
                                .transform_values { |_v| SecureRandom.hex }

      append_opts = timestamp, temp_files

      create_temp_folder(append_opts)
      create_temp_files(append_opts)
      append_files(append_opts, &watcher)
      destroy_temp_folder(append_opts)
    end

    # Vopies the sources from copy_files to destination paths
    def copy_files(&watcher)
      return nil if upload_files.empty? && download_files.empty?

      Net::SCP.start(*ssh_options) do |scp|
        upload_files.each do |local_file, remote_path|
          scp.upload! local_file, remote_path

          @result << ["scp #{local_file} #{remote_path}", ['']]
          watcher.call(@result.last.first) if block_given?
        end

        download_files.each do |remote_path, local_file|
          scp.download! remote_path, local_file

          @result << ["scp #{remote_path} #{local_file}", ['']]
          watcher.call(@result.last.first) if block_given?
        end
      end
    end

    private

    # Given a timestamp and tempname hash +append_opts+, writes the text_block lines out to it
    def create_temp_files(append_opts)
      Net::SCP.start(*ssh_options) do |scp|
        command_group.text_blocks.each do |filepath, lines|
          contents = StringIO.new(lines.join("\n") << "\n")
          remote = "/tmp/pi_maker_#{append_opts[0]}/#{append_opts[1][filepath]}"

          scp.upload!(contents, remote)

          @result << ["scp #{remote}", ['']]
        end
      end
    end

    # Given a timestamp and tempname hash +append_opts+, appends the contents of the tempfiles
    def append_files(append_opts, &watcher)
      Net::SSH.start(*ssh_options) do |connection|
        command_group.text_blocks.each do |filepath, _l|
          connection.open_channel do |ssh|
            src_path = "/tmp/pi_maker_#{append_opts[0]}/#{append_opts[1][filepath]}"
            cmd = "cat #{src_path} >> #{filepath}"

            ssh.exec(cmd)

            @result << [cmd, ['']]
            watcher.call(@result.last.last.last) if block_given?
          end.wait
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
      opts = config.slice(:hostname, :user).values
      opts << { password: config[:password] } if config[:password]

      opts
    end
  end
end
