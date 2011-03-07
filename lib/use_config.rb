require 'use_config/version'
require 'use_config/configuration'

# Extends the calling class with UseConfig::ClassMethods
module UseConfig
  def self.included(base) # :nodoc:
    base.extend ClassMethods
  end

  # Extends the Object class with UseConfig::ClassMethods
  # When UseConfig::ObjectExtend included, all the UseConfig::ClassMethods
  # methods been added to Object and all its derivatives.
  module ObjectExtend
    def self.included(base) # :nodoc:
      Object.extend ClassMethods
    end
  end

  # This module contains class methods use_config and drop_config.
  module ClassMethods
    # Adds configuration hash readed from config/name.yaml file
    # to configuration class, and generates configuration access methods.
    def use_config(name, options = {}, &block)
      metaclass = class << self; self; end

      if self.respond_to? name
        conf = self.send(name)
        unless conf.respond_to? :configuration? and conf.configuration?
          raise "Method '#{name}' already in use"
        end
      end

      # Generates class accessor.
      metaclass.instance_eval do
        attr_accessor name
      end
      self.send "#{name}=".to_sym, UseConfig::Configuration.add_conf(self, name, options, &block)

      # Generates instance accessor.
      class_eval <<-EVAL
        def #{name}
          self.class.#{name}
        end
      EVAL
    end # def use_config(name, options = {}, &block)

    # Removes configuration access methods
    def drop_config(name, options = {})
      if respond_to? name
        conf = send(name)
        if conf.respond_to? :configuration? and conf.configuration?
          UseConfig::Configuration.drop_conf(self, name)
          metaclass = class << self; self; end
          metaclass.instance_eval do
            remove_method name.to_sym
          end
          remove_method name.to_sym
        end
      end
    end
  end
end

