# frozen_string_literal: true

require 'forwardable'

module PiMaker
  # CLI Command runner
  class Command
    extend Forwardable

    def_delegators :command, :run

    # Execute this command
    def execute(*)
      return run_interactive if @options[:interactive]

      run
    end

    # The external commands runner
    def command(options = {})
      require 'tty-command'
      TTY::Command.new(options)
    end

    # Open a file or text in the user's preferred editor
    def editor_text(txt = '')
      require 'tty-editor'

      preferred = ENV['EDITOR']
      present = first_exec(*TTY::Editor::EXECUTABLES.map { |e| e.split(' ').first })

      tf = Tempfile.create
      tf.write(txt)
      tf.rewind

      system("#{(preferred || present)} #{tf.path}")

      File.read(tf.path)
    end

    # File manipulation utility methods
    def generator
      require 'tty-file'
      TTY::File
    end

    # Terminal output paging
    def pager(options = {})
      require 'tty-pager'
      TTY::Pager.new(options)
    end

    # The interactive prompt
    def prompt(options = {})
      require 'tty-prompt'
      TTY::Prompt.new(options)
    end

    # The unix which utility
    def which(*args)
      require 'tty-which'
      TTY::Which.which(*args)
    end

    # Check if executable exists
    def exec_exist?(*args)
      require 'tty-which'
      args.any? { |a| TTY::Which.exist?(a) }
    end

    # Detect if any of these executables exist
    def first_exec(*args)
      require 'tty-which'
      args.detect { |a| TTY::Which.exist?(a.split(' ').first) }
    end
  end
end
