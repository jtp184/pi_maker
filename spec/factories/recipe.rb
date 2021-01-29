FactoryBot.define do
  factory :recipe, class: OpenStruct do
    apt_packages { %w[kitty] }

    github_repos do
      {
        'jtp184/arch_dotfiles' => [
          'git clone git@github.com:jtp184/arch_dotfiles.git',
          'cd ~/repos/arch_dotfiles',
          'cp -ri ./home/* ~/',
          'mkdir -p ~/.config',
          'cp -ri ./config/* ~/.config'
        ],
        'rails' => []
      }
    end

    gems { %w[bundler pry colorize tty-prompt] }
    shell { ['touch ~/.hushlogin', 'utime'] }

    bashrc do
      [
        "export RECIPEOPTION=#{SecureRandom.hex}"
      ]
    end

    initialize_with { PiMaker::Recipe.new(**attributes) }
  end
end
