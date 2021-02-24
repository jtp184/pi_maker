module PiMaker
  # Stores recipes and wifi networks together in a securable bundle
  class Pantry
    # The base directory to check in for files
    attr_accessor :base_path
    # An optional password to encrypt files in the pantry
    attr_accessor :password
    # Add new recipes as a collection
    attr_accessor :recipes
    # Add new wifi networks as a collection
    attr_accessor :wifi_networks
    # Paths where files are stored at
    attr_accessor :file_paths

    # Matches encoded or unencoded yaml files
    FILE_EXT = '(?:\.enc)?\.ya?ml$'.freeze
    # Checks for a wifi config, encoded or not
    WIFI_CONFIG_FILENAME = '\bwifi_config\.(enc\.)?ya?ml$'.freeze
    # What to call a password file stored locally
    PASSWORD_FILE_NAME = '.pantry_password'.freeze

    # Takes in +opts+ for the +base_path+ and an optional +password+
    def initialize(opts = {})
      @base_path = opts.fetch(:base_path)
      @file_paths = {}

      @password = opts.fetch(:password) do
        fpath = base_path + "/#{PASSWORD_FILE_NAME}"
        File.exist?(fpath) ? File.read(fpath) : nil
      end

      @recipes = opts.fetch(:recipes, load_recipes)

      @wifi_networks = opts.fetch(:wifi_networks, load_wifi_networks)
    end

    # If we can locate a global pantry, loads it. Override with +opts+
    def self.global(opts = {})
      if global_exists? && !opts.key(:base_path)
        new({ base_path: File.read("#{global_exists?}/.pi_maker") }.merge(opts))
      else
        new({ base_path: Dir.pwd }.merge(opts))
      end
    end

    # Return nil if we can't find a dotfile, or the containing directory
    def self.global_exists?
      [Dir.pwd, Dir.home, "#{Dir.home}/.config/pi_maker"].detect do |pth|
        File.exist?("#{pth}/.pi_maker")
      end
    end

    # Given an optional +where_path+ to save to, saves out the recipes and wifi config
    # to the folder
    def write(opts = {})
      store_path = Pathname.new(opts[:path] || base_path)
      passwd = opts.fetch(:password, password)
      file_ext = passwd ? '.enc.yml' : '.yml'

      Dir.mkdir(store_path) unless Dir.exist?(store_path)
      Dir.mkdir(store_path.join('recipes')) unless Dir.exist?(store_path.join('recipes'))

      unless wifi_networks.empty?
        File.open(store_path.join("wifi_config#{file_ext}"), 'w+b') do |f|
          f << FileEncrypter.encrypt(Psych.dump(wifi_networks), passwd)
        end
      end

      recipes.each do |rec|
        fname = "#{rec.hostname}_recipe#{file_ext}"

        File.open(store_path.join('recipes').join(fname), 'w+b') do |f|
          f << rec.to_yaml(passwd)
        end
      end

      if opts.fetch(:password_file, true) && passwd
        File.open(store_path.join('.pantry_password'), 'w+') { |f| f << passwd }
      end

      self
    end

    # Loads recipes and wifi networks from their paths
    def reload
      @file_paths = {}
      @recipes = load_recipes
      @wifi_networks = load_wifi_networks
      self
    end

    # Empties recipes and wifi networks
    def clear
      @recipes = []
      @wifi_networks = {}
      self
    end

    def exists?
      Dir.exist?(root_path('recipes'))
    end

    private

    # Finds and interprets a wifi config file in the base path
    def load_wifi_networks
      fi = Dir.exist?(root_path) && file_present?(WIFI_CONFIG_FILENAME)

      return {} unless fi

      inst = Psych.load(FileEncrypter.decrypt(File.read(fi), password))
      file_paths[inst] = fi
      inst
    end

    # Finds and interprets and recipes files in the recipes subdirectory
    def load_recipes
      return [] unless Dir.exist?(root_path('recipes'))

      file_list(root_path('recipes')).map do |recipe|
        next unless recipe =~ /#{FILE_EXT}/

        inst = Recipe.from_yaml(File.read(recipe), password)
        file_paths[inst] = recipe
        inst
      end
    end

    # Returns a Pathname of the base path with optional subdirectories as +joins+
    def root_path(*joins)
      return base_path if joins.empty?

      Pathname.new(base_path).join(*joins)
    end

    # Checks the file_list with optional +path+ and checks if any matches regex +file+
    def file_present?(file, path = root_path)
      file_list(path).detect { |f| f.match?(file) }
    end

    # Returns Dir.[] for the +path+
    def file_list(path = root_path)
      Dir["#{path}/*"]
    end
  end
end
