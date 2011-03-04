require 'rubygems'
require 'yaml'
require 'thread'

require 'hash_access'

module UseConfig
  include HashAccess

  # UseConfig::Configuration class plays two roles.
  #
  # An instance of the class is a hash, a placeholder for configuration.
  # It contents could be loaded from a YAML file or could be populated
  # manually. Configuration values can be accessed using the hash notation
  # +object['key']+ as well as using the method notation +object.key+.
  #
  # The class itself is a container. It containas above-mentioned configuration
  # objects that are stored in the +conf+ hash attribute which is accessible
  # by the +conf+ method.
  #
  # A particular instance should be created with the +add_conf+ method.
  # It is not intended to use as an instance as a standalone object.
  #
  # Usage example:
  #
  #     UseConfig::Configuration.add_conf self, :qwerty, :empty => true
  #     UseConfig::Configuration.conf.qwerty.param_1 = 'Value 1'
  #     print UseConfig::Configuration.conf.qwerty.to_s, "\n"
  #
  # This class is designed as the UseConfig supplemental class. It is not very
  # useful by its own.
  class Configuration < Hash
    class << self
      attr_accessor :accessors
      attr_accessor :default_config_path
      attr_accessor :extentions
      attr_accessor :conf
      attr_accessor :settings
      attr_accessor :mutex
    end

    self.mutex = Mutex.new

    self.conf = {}
    self.settings = {}

    self.accessors = [ :name, :config_path, :config_file, :use_config_file, :extentions, :used_by ]
    self.default_config_path = [ '.', 'config' ]
    self.extentions = [ 'yml', 'yaml' ]

    self.accessors.each do |a|
      attr_accessor a
    end

    # Creates a new config (an instance of +self+) (calls +self.new+)
    # and inserts the result object it into +self.conf+ hash as
    # +self.conf[name]+ element. If the config already exists and the
    # +:reload_when_add+ class setting is set - reloads config contents.
    #
    # Returns the created config object.
    #
    # Parameters
    #
    # * +used_by+ - The class that uses the config. After the config created
    #   created, this class is assotiated with it. This prevents the config to
    #   be deleted if any class uses it.
    # * +name+ - Config name. It is used as the +conf+ hash key.
    # * +options+ - The options hash to be passed to +new+.
    #
    # Options
    #
    # * +:empty+ - Create an empty config. Don't use a YAML file to load data.
    # * +:file+ - Use the mentioned file instead of the default.
    # * +:path_insert+ - Add this value to the beginning of the configuration
    #   files' search path.
    def self.add_conf(used_by, name, options = {}, &block)
      sname = name.to_s
      self.mutex.synchronize do
        if self.conf[sname]
          self.conf[sname].reload! if self.settings[:reload_when_add]
          self.conf[sname].used_by_add(used_by)
          yield self.conf[sname] if block_given?
        else
          self.conf[sname] = self.new(sname, options, &block)
          self.conf[sname].used_by_add(used_by)
        end
        self.conf[sname]
      end # self.mutex.synchronize do
    end

    # Deletes the config if it is not in use.
    def self.drop_conf(used_by, name)
      sname = name.to_s
      self.mutex.synchronize do
        if self.conf[sname]
          self.conf[sname].used_by_drop(used_by)
          if self.conf[sname].used_by.size == 0
            self.conf.delete(sname)
          end
        end
      end # self.mutex.synchronize do
    end

    # Instance methods

    def configuration?
      true
    end

    def initialize(name, options = {}, &block)
      self.name = name.to_s
      self.config_path = self.class.default_config_path.clone
      self.config_file = nil
      self.use_config_file = true
      self.extentions = self.class.extentions
      self.used_by = []
      if options[:file]
        self.config_file = options[:file]
      end
      if options[:path_insert]
        if options[:path_insert].is_a? Array
          options[:path_insert].reverse.each do |dir|
            self.config_path.unshift(dir)
          end
        else
          self.config_path.unshift(options[:path_insert])
        end
      end
      if options[:empty]
        self.use_config_file = false
      end
      if use_config_file and config_file.nil?
        config_file_find
        if config_file.nil?
          raise "Configuration file not found"
        end
        load_configuration
      end
      self.access_by_methods
      yield self if block_given?
      self
    end # def initialize

    # Adds the class to usage list.
    def used_by_add(used_by)
      self.used_by.push(used_by) unless self.used_by.include?(used_by)
      self
    end

    # Removes the class from usage list.
    def used_by_drop(used_by)
      if self.used_by.include?(used_by)
        self.used_by.delete(used_by)
      end
      self
    end

    # Serches for configuration file.
    def config_file_find
      self.config_path.each do |dir|
        self.extentions.each do |ext|
          file = "#{dir}/#{name}.#{ext}"
          if File.exist?(file)
            self.config_file = file
            return self
          end
        end
      end
      self
    end # def config_file_find

    # Loads configuration from file +config_file+.
    def load_configuration
      cfg = YAML.load_file(config_file)
      cfg.each do |key, value|
        next if self.class.accessors.include?(key.to_sym)
        self[key] = value
      end
      self
    end

    # Removes all the keys from itself.
    def clear!
      each_key do |key|
        next if self.class.accessors.include?(key.to_sym)
        delete(key)
      end
      yield self if block_given?
      self
    end

    # Reloads configuration from file.
    def reload!
      clear!
      load_configuration if use_config_file
      yield self if block_given?
      self
    end
  end # class Configuration
end # module UseConfig

