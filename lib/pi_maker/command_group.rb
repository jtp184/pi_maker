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
      pre_commands
      build_text_blocks
    end

    # Generate commands from the different recipe collections
    def build_commands
      @commands = PiMaker::Recipe::LINES.reduce([]) do |acc, field|
        acc << send(field)
      end.flatten!
    end

    # Build text blocks to be copied and appended to files
    def build_text_blocks
      @text_blocks = PiMaker::Recipe::TEXT_BLOCKS.map do |field, path|
        [path, recipe.public_send(field)]
      end.to_h
    end

    # Prepends the commands array with one off lines
    def pre_commands
      @commands.unshift('sudo apt-get update') if recipe[:apt_packages] || recipe[:gems]
      @commands.unshift('mkdir ~/repos') if recipe[:github_repos]
    end

    # Construct an apt-get install string from the packages
    def apt_packages
      recipe.apt_packages.reduce('sudo apt-get install --y') { |str, pkg| [str, pkg].join(' ') }
    end

    # Construct an array of git clone strings from the repos
    def github_repos
      recipe.github_repos.map do |ghr|
        repo_args = ghr.match(%r{(\w+)(?:/(\w+))?})
        url_str = "#{repo_args[1]}/#{repo_args[2] || repo_args[1]}"

        "git clone https://github.com/#{url_str}.git ~/repos"
      end
    end

    # Construct a gem install string from the gems
    def gems
      recipe.gems.reduce('sudo gem install') { |str, gm| [str, gm].join(' ') }
    end
  end
end
