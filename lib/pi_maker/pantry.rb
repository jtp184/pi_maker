module PiMaker
  class Pantry
    attr_accessor :base_path
    attr_accessor :password

    FILE_EXT = 'enc|ya?ml$'.freeze
    WIFI_CONFIG_FILENAME = '\bwifi_config\.(enc\.)?ya?ml$'.freeze

    def initialize(opts = {})
      @base_path = opts.fetch(:base_path)
      @password = opts.fetch(:password, nil)
    end

    def reload
      @recipes = @wifi_networks = nil
      self
    end

    def recipes
      @recipes ||= Dir["#{root_path('recipes')}/*"].map do |recipe|
        next unless recipe =~ /#{FILE_EXT}/

        Recipe.from_yaml(File.read(recipe), password)
      end
    end

    def wifi_networks
      return unless file_present?(/#{WIFI_CONFIG_FILENAME}/)

      @wifi_networks ||= Psych.load(
        FileEncrypter.call(
          File.read(file_list.detect { |d| d.match?(/#{WIFI_CONFIG_FILENAME}/) }),
          password
        )
      )
    end

    private

    def root_path(*joins)
      return base_path if joins.empty?

      Pathname.new(base_path).join(*joins)
    end

    def file_present?(file, path = root_path)
      file_list(path).any? { |f| f.match?(file) }
    end

    def file_list(path = root_path)
      Dir["#{path}/*"]
    end
  end
end
