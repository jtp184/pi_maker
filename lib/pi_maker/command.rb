# frozen_string_literal: true

require 'forwardable'

module PiMaker
  class Command
    extend Forwardable

    def_delegators :command, :run

    # Execute this command
    def execute(*)
      raise(
        NotImplementedError,
        "#{self.class}##{__method__} must be implemented"
      )
    end

    # The external commands runner
    def command(**options)
      require 'tty-command'
      TTY::Command.new(options)
    end

    # The cursor movement
    def cursor
      require 'tty-cursor'
      TTY::Cursor
    end

    # Open a file or text in the user's preferred editor
    def editor
      require 'tty-editor'
      TTY::Editor
    end

    # File manipulation utility methods
    def generator
      require 'tty-file'
      TTY::File
    end

    # Terminal output paging
    def pager(**options)
      require 'tty-pager'
      TTY::Pager.new(options)
    end

    # Terminal platform and OS properties
    def platform
      require 'tty-platform'
      TTY::Platform.new
    end

    # The interactive prompt
    def prompt(**options)
      require 'tty-prompt'
      TTY::Prompt.new(options)
    end

    # Get terminal screen properties
    def screen
      require 'tty-screen'
      TTY::Screen
    end

    # The unix which utility
    def which(*args)
      require 'tty-which'
      TTY::Which.which(*args)
    end

    # Check if executable exists
    def exec_exist?(*args)
      require 'tty-which'
      TTY::Which.exist?(*args)
    end
  end
end
