FactoryBot.define do
  factory :recipe, class: OpenStruct do
    gems { %w[bundler pry colorize tty-prompt] }
    apt_packages { %w[kitty] }
    github_repos { %w[jtp184/arch_dotfiles rails] }
    bashrc { "export RECIPEOPTION=#{SecureRandom.hex}" }

    initialize_with { PiMaker::Recipe.new(**attributes) }
  end
end
