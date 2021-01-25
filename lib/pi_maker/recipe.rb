module PiMaker
  # Definable inside a gem, passes options to it
  class Recipe
    # Defined attributes on the class
    ATTRS = %i[
      apt_packages
      bashrc
      github_repos
      gems
    ].freeze

    attr_reader(*ATTRS)

    # Use the +opts+ hash to populate instance vars
    def initialize(opts = {})
      opts.to_h.each do |key, value|
        next unless ATTRS.include?(key)

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
