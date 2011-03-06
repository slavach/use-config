require 'rubygems'
require 'yaml'
require 'thread'

require 'hash_access'

module UseConfig
  # UseConfig::Configuration class plays two roles.
  #
  # An instance of the class is a hash, a configuration placeholder.
  # It contents could be loaded from a YAML file or could be populated
  # manually. Configuration values can be accessed using the hash notation
  # +object['key']+ as well as using the method notation +object.key+.
  #
  # The class itself is a container. It containas above-mentioned configuration
  # objects that are stored in the +conf+ hash attribute which is accessible
  # by the +conf+ method.
  #
  # A particular instance should be created with the +add_conf+ method.
  # It is not intended to use an instance as a standalone object.
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
    include HashAccess

    class << self
      attr_accessor :path
      attr_accessor :extentions
      attr_accessor :reload_when_add
      attr_accessor :default_instance_properties
      attr_accessor :conf
      attr_accessor :mutex
    end

    self.path = %w[. config]
    self.extentions = %w[yml yaml]
    self.reload_when_add = false

    self.default_instance_properties = {
      :name => nil,
      :file => nil,
      :use_file => true,
      :path => self.path,
      :extentions => self.extentions,
      :used_by => [],
    }

    self.conf = {}

    self.mutex = Mutex.new

    # Passes self to calling block.
    #
    # Example:
    #
    #   UseConfig::Configuration.configure do |c|
    #     c.path << APP_ROOT + 'config'
    #   end
    #
    def self.configure
      yield self if block_given?
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
    # * +name+ - Config name. It is used as the +conf+ hash key as well as the
    #   attribute of the config itself.
    # * +options+ - The options hash to be passed to +new+.
    #
    # Options
    #
    # * +:empty+ - Create an empty config. Don't load config from file.
    # * +:file+ - Use the mentioned file instead of the default.
    #   files' search path.
    def self.add_conf(used_by, name, options = {}, &block)
      sname = name.to_s
      self.mutex.synchronize do
        if self.conf[sname]
          self.conf[sname].reload! if self.reload_when_add
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

    # Deletes all configs.
    def self.reset!
      self.mutex.synchronize do
        self.conf = {}
      end
    end

    # Instance behavior

    attr_accessor :instance_properties

    # What's this?
    def configuration?
      true
    end

    # Passes self to a calling block.
    def configure(&block)
      yield self if block_given?
    end

    # Initializes a new instance. Load configuration from file if given.
    #
    # Parameters:
    #
    # * +name+ - The object's name.
    # * +options+ - Options' hash.
    #
    # Options:
    #
    # * +:empty: - Create empty object, don't read configuration from file.
    # * No other options yet.
    #
    # Notes:
    #
    # Doesn't add any +use_by+ properties, even being passed in +options+.
    # +use_by+ should be added later, by the caller, using +add_use_by+
    # method.
    def initialize(name, options, &block)
      self.instance_properties = {}.access_by_methods
      self.class.default_instance_properties.keys.each do |key|
        if options[key].nil?
          instance_properties[key] = self.class.default_instance_properties[key]
        else
          instance_properties[key] = options[key]
        end
      end
      instance_properties.name = name.to_s
      instance_properties.used_by = []
      if options[:empty]
        instance_properties.use_file = false
      end
      if instance_properties.use_file and instance_properties.file.nil?
        config_file_find
        if instance_properties.file.nil?
          raise "Configuration file not found"
        end
        load_configuration
      end
      self.access_by_methods
      yield self if block_given?
      self
    end # def initialize

    private

    # Sets +name+ property.
    def set_name(name)
      if name
        self.instance_properties.name = name.to_s
      end
    end

    # Adds the class to usage list.
    def used_by_add(used_by)
      unless self.instance_properties.used_by.include?(used_by)
        self.instance_properties.used_by.push(used_by)
      end
    end

    # Removes the class from usage list.
    def used_by_drop(used_by)
      if self.instance_properties.used_by.include?(used_by)
        self.instance_properties.used_by.delete(used_by)
      end
    end

    # Returns +used_by+ property
    def used_by
      self.instance_properties.used_by
    end

    # Serches for configuration file.
    def config_file_find
      instance_properties.path.each do |dir|
        instance_properties.extentions.each do |ext|
          file = "#{dir}/#{self.instance_properties.name}.#{ext}"
          if File.exist?(file)
            self.instance_properties.use_file = true
            self.instance_properties.file = file
          end
        end
      end
    end # def config_file_find

    # Loads configuration from the +config_file+.
    # TODO: rename this function to +load+
    def load_configuration
      begin
        cfg = YAML.load_file(instance_properties.file)
        cfg.each do |key, value|
          self[key] = value
        end
        true
      rescue
        false
      end
    end

    # Removes all the keys from itself.
    def clear!
      self.clear
    end

    # Reloads configuration from file.
    def reload!
      self.clear!
      if (instance_properties.file && instance_properties.use_file)
        load_configuration
      end
    end
  end # class Configuration
end # module UseConfig

