require 'tty-which'

module PiMaker
  # Generate the actual shell commands from a Ingredients
  class CommandGroup
    include Enumerable

    # Ingredients generates commands and text_blocks
    attr_reader :ingredients

    # Take +opts+ in to capture the ingredients
    def initialize(opts = {})
      @ingredients = opts.fetch(:ingredients, Ingredients.new)
    end

    # Use the +method_name+ on the ingredients
    def method_missing(method_name, *args, &blk)
      super unless ingredients.respond_to?(method_name)

      ingredients.public_send(method_name, *args, &blk)
    end

    # Respond to the +method_name+ on the ingredients
    def respond_to_missing?(method_name, priv)
      ingredients.respond_to?(method_name, priv) || super
    end

    # Generate commands from the different ingredients collections
    def commands
      cmds = PiMaker::Ingredients::LISTS.reduce([]) do |acc, field|
        acc << (ingredients.public_send(field[0]).nil? ? nil : send(field[0]))
        acc
      end.compact

      cmds.unshift('mkdir -p ~/repos') if ingredients[:github_repos]
      cmds.unshift('sudo apt-get update') if ingredients[:apt_packages] || ingredients[:gems]

      cmds.flatten
    end

    # Build text blocks to be copied and appended to files
    def text_blocks
      PiMaker::Ingredients::TEXT_BLOCKS.map { |field, path| [path, ingredients.public_send(field)] }
                                       .reject { |b| b[1].nil? }
                                       .to_h
    end

    # Construct an apt-get install string from the packages
    def apt_packages
      ingredients.apt_packages.reduce('sudo apt-get install -y') { |str, pkg| [str, pkg].join(' ') }
    end

    # Construct an array of git clone strings from the repos
    def github_repos
      ingredients.github_repos.map do |ghr, post_install|
        repo_args = ghr.match(%r{(\w+)(?:/(\w+))?})
        url_str = "#{repo_args[1]}/#{repo_args[2] || repo_args[1]}"

        [
          "git clone https://github.com/#{url_str}.git ~/repos/#{repo_args[2] || repo_args[1]}",
          post_install
        ]
      end
    end

    # Use the raspi-config tool on the pi for these options
    def raspi_config
      ingredients.raspi_config.map do |k, v|
        %(sudo raspi-config nonint #{k}#{v ? " #{v}" : ''})
      end
    end

    # Construct a gem install string from the gems
    def gems
      ingredients.gems.reduce('sudo gem install') { |str, gm| [str, gm].join(' ') }
    end
  end
end
