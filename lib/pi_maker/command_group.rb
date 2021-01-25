require 'tty-which'

module PiMaker
  # Generate the actual shell commands from a Recipe
  class CommandGroup
    include Enumerable

    # Recipe generates commands and text_blocks
    attr_reader :recipe, :commands, :text_blocks

    # Take +opts+ in to capture the recipe
    def initialize(opts = {})
      @recipe = opts.fetch(:recipe)
      build
    end

    private

    # Returns a list of commands to run generated from the recipe
    def build
      build_commands
      build_text_blocks
    end

    # Generate commands from the different recipe collections
    def build_commands
      @commands = []

      @commands << 'sudo apt-get update' if recipe.apt_packages || recipe.gems
      @commands << apt_packages if recipe&.apt_packages
      @commands << 'mkdir ~/repos' if recipe&.github_repos
      @commands += github_repos if recipe&.github_repos
      @commands << gems if recipe&.gems
    end

    # Build text blocks to be copied and appended to files
    def build_text_blocks
      txt = {}
      txt['/home/pi/.bashrc'] = recipe.bashrc if recipe&.bashrc

      @text_blocks = txt
    end

    # Construct an apt-get install string from the packages
    def apt_packages
      recipe.apt_packages.reduce('sudo apt-get install --y') { |str, pkg| [str, pkg].join(' ') }
    end

    # Construct an array of git clone strings from the repos
    def github_repos
      recipe.github_repos.map { |ghr| git_clone(ghr) }
    end

    # Construct a gem install string from the gems
    def gems
      recipe.gems.reduce('sudo gem install') { |str, gm| [str, gm].join(' ') }
    end

    # Parse the +repo_str+ to create a git clone string
    def git_clone(repo_str)
      repo_args = repo_str.match(%r{(?<user>\w+)(?:/(?<repo>\w+))?})
                          .named_captures
                          .transform_keys(&:to_sym)

      "git clone https://github.com/#{repo_args[:user]}/#{repo_args[:repo] || repo_args[:user]} ~/"
    end
  end
end
