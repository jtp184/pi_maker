require 'tty-which'

module PiMaker
  # Generate the actual shell commands from a Instructions
  class CommandGroup
    include Enumerable

    # Instructions generates commands and text_blocks
    attr_reader :instructions

    # Take +opts+ in to capture the instructions
    def initialize(opts = {})
      @instructions = opts.fetch(:instructions, Instructions.new)
    end

    # Use the +method_name+ on the instructions
    def method_missing(method_name, *args, &blk)
      super unless instructions.respond_to?(method_name)

      instructions.public_send(method_name, *args, &blk)
    end

    # Respond to the +method_name+ on the instructions
    def respond_to_missing?(method_name, priv)
      instructions.respond_to?(method_name, priv) || super
    end

    # Generate commands from the different instructions collections
    def commands
      cmds = PiMaker::Instructions::LISTS.each_with_object([]) do |field, acc|
        acc << (instructions.public_send(field[0]).nil? ? nil : send(field[0]))
      end.compact

      cmds.unshift('mkdir -p ~/repos') unless instructions[:github_repos].empty?

      unless instructions[:apt_packages].empty? || instructions[:gems].empty?
        cmds.unshift('sudo apt-get update')
      end

      cmds.flatten
    end

    # Build text blocks to be copied and appended to files
    def text_blocks
      PiMaker::Instructions::TEXT_BLOCKS.map { |field, path| [path, instructions.public_send(field)] }
                                       .reject { |b| b[1].nil? || b[1].empty? }
                                       .to_h
    end

    # Construct an apt-get install string from the packages
    def apt_packages
      return if instructions.apt_packages.empty?

      instructions.apt_packages.reduce('sudo apt-get install -y') { |str, pkg| [str, pkg].join(' ') }
    end

    # Construct an array of git clone strings from the repos
    def github_repos
      instructions.github_repos.map do |ghr, post_install|
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
      instructions.raspi_config.map do |k, v|
        value = if v.nil?
                  ''
                elsif v.is_a?(String)
                  " #{v}"
                elsif v.is_a?(Array)
                  " #{v.one? ? v.first : v.join(' ')}"
                end

        %(sudo raspi-config nonint #{k}#{value})
      end
    end

    # Construct a gem install string from the gems
    def gems
      return if instructions.gems.empty?

      instructions.gems.reduce('sudo gem install') { |str, gm| [str, gm].join(' ') }
    end
  end
end
