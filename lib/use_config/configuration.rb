require 'rubygems'
require 'yaml'
require 'thread'

gem 'hash-access'

module UseConfig
  include HashAccess

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

    def self.add_conf(used_by, name, options = {}, &block)
      sname = name.to_s
      self.mutex.synchronize do
        if self.conf[sname]
          self.conf[sname].reload! if self.settings[:reload_when_add]
          self.conf[sname].used_by_add(used_by)
          yield self.conf[sname] if block_given?
        else
          self.conf[sname] = UseConfig::Configuration.new(sname, options, &block)
          self.conf[sname].used_by_add(used_by)
        end
        self.conf[sname]
      end # self.mutex.synchronize do
    end

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
      access_by_methods
      yield self if block_given?
      self
    end # def initialize(name, options = {}, &block)

    def used_by_add(used_by)
      self.used_by.push(used_by) unless self.used_by.include?(used_by)
      self
    end

    def used_by_drop(used_by)
      if self.used_by.include?(used_by)
        self.used_by.delete(used_by)
      end
      self
    end

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

    def load_configuration
      cfg = YAML.load_file(config_file)
      cfg.each do |key, value|
        next if self.class.accessors.include?(key.to_sym)
        self[key] = value
      end
      self
    end

    def clear!
      each_key do |key|
        next if self.class.accessors.include?(key.to_sym)
        delete(key)
      end
      yield self if block_given?
      self
    end

    def reload!
      clear!
      load_configuration if use_config_file
      yield self if block_given?
      self
    end
  end # class Configuration
end # module UseConfig

