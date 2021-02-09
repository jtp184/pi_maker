require 'tty-which'

module PiMaker
  # Generate the actual shell commands from a Recipe
  class CommandGroup
    include Enumerable

    # Recipe generates commands and text_blocks
    attr_reader :recipe

    # Take +opts+ in to capture the recipe
    def initialize(opts = {})
      @recipe = opts.fetch(:recipe, Recipe.new)
    end

    # Use the +method_name+ on the recipe
    def method_missing(method_name, *args, &blk)
      super unless recipe.respond_to?(method_name)

      recipe.public_send(method_name, *args, &blk)
    end

    # Respond to the +method_name+ on the recipe
    def respond_to_missing?(method_name, priv)
      recipe.respond_to?(method_name, priv) || super
    end

    # Generate commands from the different recipe collections
    def commands
      cmds = PiMaker::Recipe::LISTS.reduce([]) do |acc, field|
        acc << send(field[0])
      end

      cmds.unshift('mkdir ~/repos') if recipe[:github_repos]
      cmds.unshift('sudo apt-get update') if recipe[:apt_packages] || recipe[:gems]

      cmds.flatten
    end

    # Build text blocks to be copied and appended to files
    def text_blocks
      PiMaker::Recipe::TEXT_BLOCKS.map { |field, path| [path, recipe.public_send(field)] }
                                  .reject { |b| b[1].nil? }
                                  .to_h
    end

    # Construct an apt-get install string from the packages
    def apt_packages
      recipe.apt_packages.reduce('sudo apt-get install -y') { |str, pkg| [str, pkg].join(' ') }
    end

    # Construct an array of git clone strings from the repos
    def github_repos
      recipe.github_repos.map do |ghr, post_install|
        repo_args = ghr.match(%r{(\w+)(?:/(\w+))?})
        url_str = "#{repo_args[1]}/#{repo_args[2] || repo_args[1]}"

        [
          "git clone https://github.com/#{url_str}.git ~/repos/#{repo_args[2] || repo_args[1]}",
          post_install
        ]
      end
    end

    # Construct a gem install string from the gems
    def gems
      recipe.gems.reduce('sudo gem install') { |str, gm| [str, gm].join(' ') }
    end
  end
end
