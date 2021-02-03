FactoryBot.define do
  factory :recipe, class: OpenStruct do
    apt_packages { %w[kitty] }

    github_repos do
      {
        'jtp184/arch_dotfiles' => [
          'cp -ri ~/repos/arch_dotfiles/home ~/',
          'mkdir -p ~/.config',
          'cp -ri ~/repos/config ~/.config'
        ],
        'M0nica' => []
      }
    end

    gems { %w[colorize tty-prompt] }
    shell { ['touch ~/.hushlogin', 'utime'] }

    bashrc do
      [
        "export RECIPEOPTION_#{Time.now.to_i}=#{SecureRandom.hex}"
      ]
    end

    initialize_with { PiMaker::Recipe.new(**attributes) }
  end
end
