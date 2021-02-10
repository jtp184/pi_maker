FactoryBot.define do
  factory :recipe, class: OpenStruct do
    apt_packages { %w[kitty] }

    github_repos do
      {
        'jtp184/arch_dotfiles' => [
          'mkdir -p ~/.config',
          'cp -ri ~/repos/arch_dotfiles/config ~/.config'
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

    raspi_config do
      {
        do_spi: 0,
        do_expand_rootfs: nil
      }
    end

    initialize_with { PiMaker::Recipe.new(**attributes) }
  end
end
