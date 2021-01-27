module PiMaker
  # Definable inside a gem, passes options to it
  class Recipe
    # Defined attributes on the class which are to generate shell lines
    LINES = %i[
      apt_packages
      github_repos
      gems
    ].freeze

    # Defined attributes which are to be included into files
    TEXT_BLOCKS = {
      bashrc: '/home/pi/.bashrc'
    }.freeze

    attr_reader(*LINES, *TEXT_BLOCKS.keys)

    # Use the +opts+ hash to populate instance vars
    def initialize(opts = {})
      opts.to_h.each do |key, value|
        next unless LINES.include?(key) || TEXT_BLOCKS.include?(key)

        instance_variable_set(:"@#{key}", value)
      end
    end

    # Yield to a block, or directly use the +hsh+ to create a new instance
    def self.define(hsh = {})
      opts = OpenStruct.new(hsh)
      yield opts if block_given?
      new(opts)
    end
  end
end
