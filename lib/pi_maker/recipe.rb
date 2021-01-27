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

    # Generate accessors for the defined attributes
    attr_reader(*LINES, *TEXT_BLOCKS.keys)

    # Use the +opts+ hash to populate instance vars
    def initialize(opts = {})
      opts.to_h.each do |key, value|
        next unless valid_attribute?(key)

        instance_variable_set(:"@#{key}", value)
      end
    end

    # Yield to a block, or directly use the +hsh+ to create a new instance
    def self.define(hsh = {})
      opts = OpenStruct.new(hsh)
      yield opts if block_given?
      new(opts)
    end

    # If the +field+ is valid, get its value
    def [](field)
      valid_attribute?(field) ? public_send(field) : nil
    end

    private

    # Returns true if the +key+ is one of the LINES or TEXT_BLOCKS keys
    def valid_attribute?(key)
      LINES.include?(key) || TEXT_BLOCKS.keys.include?(key)
    end
  end
end
