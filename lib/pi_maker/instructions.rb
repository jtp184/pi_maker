module PiMaker
  # Set options for what to install / run
  class Instructions
    # Defined attributes on the class which store collections
    LISTS = {
      apt_packages: Array,
      gems: Array,
      github_repos: Hash,
      shell: Array,
      raspi_config: Hash
    }.freeze

    # Defined attributes which are to be included into files
    TEXT_BLOCKS = {
      bashrc: '/home/pi/.bashrc'
    }.freeze

    # Generate accessors for the defined attributes
    attr_accessor(*LISTS.keys, *TEXT_BLOCKS.keys)

    # Define a ruby version to install with rbenv
    attr_accessor :ruby_version

    # Use the +opts+ hash to populate instance vars
    def initialize(opts = {})
      opt_hash = opts.to_h

      @ruby_version = opt_hash[:ruby_version]

      LISTS.each do |c, t|
        instance_variable_set(:"@#{c}", opt_hash.key?(c.to_s) ? opt_hash[c.to_s] : t.new)
      end

      TEXT_BLOCKS.each_key do |c|
        instance_variable_set(:"@#{c}", opt_hash.key?(c.to_s) ? opt_hash[c.to_s] : [])
      end

      opt_hash.each do |key, value|
        next unless valid_attribute?(key)
        next if LISTS.include?(key) && !value.is_a?(LISTS[key])

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

    # Convert to a hash representation by map reducing the keys
    def to_h
      valid_attributes.map.with_object({}) do |val, acc|
        acc[val] = send(val) if send(val)
      end
    end

    # Combine the subvalues of self and +other+ to make new instructions
    def +(other)
      raise TypeError unless other.is_a?(self.class)

      combo = self.class.new(ruby_version: ruby_version)

      LISTS.each do |key, type|
        val = if type == Hash
                send(key).merge(other.send(key))
              elsif type == Array
                send(key) + other.send(key)
              end

        combo.send(:"#{key}=", val)
      end

      TEXT_BLOCKS.each_key do |key|
        combo.send(:"#{key}=", send(key) + other.send(key))
      end

      combo
    end

    private

    def valid_attributes
      LISTS.keys + TEXT_BLOCKS.keys + [:ruby_version]
    end

    # Returns true if the +key+ is one of the LISTS or TEXT_BLOCKS keys
    def valid_attribute?(key)
      valid_attributes.include?(key)
    end
  end
end
