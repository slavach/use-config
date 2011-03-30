# vim foldmethod=syntax

require 'rubygems'
require 'rspec'

require File.dirname(__FILE__) + "/../lib/use_config/configuration.rb"

describe UseConfig::Configuration, "instance public interface" do
  before :each do
    UseConfig::Configuration.reset!
    UseConfig::Configuration.configure do |c|
      c.path << "#{File.dirname(__FILE__)}/config"
    end
  end

  describe "#initialize" do
    describe "correct usage" do
      context "when option :empty given" do
        before :each do
          @conf = UseConfig::Configuration.new :empty_conf,
            :empty => true
        end

        it "is empty after creation" do
          @conf.should == {}
        end

        it "assigns values by methods" do
          @conf.core.name = 'conf'
          @conf.core.name.should == 'conf'
        end

        it "has instance_properties" do
          @conf.instance_properties.should_not == nil
        end

        it "has instance_properties.name" do
          @conf.instance_properties.name.should == 'empty_conf'
        end
      end

      context "when option :file given" do
        it "loads configuration from file" do
          c = UseConfig::Configuration.new :the_first_conf,
            :file => "spec/config/first_conf.yaml"
          c.core.name.should == 'first_conf'
        end
      end

      context "when option :path_insert given" do
        it "loads configuration from file from given path" do
          c = UseConfig::Configuration.new :config,
            :path_insert => "spec/config_insert"
          c.confname.should == 'config_insert_conf'
        end
      end
    end

    describe "incorrect usage" do
      context "when config file missing" do
        it "raises an error" do
          expect {
            UseConfig::Configuration.new :none_conf
          }.to raise_error
        end
      end
    end
  end
end

describe UseConfig::Configuration, "private instance methods" do
  before :each do
    module ::UseConfig
      class Configuration
        public :set_name, :used_by_add, :used_by_drop, :used_by,
          :config_file_find, :load_configuration,
          :clear!, :reload!
      end
    end

    @conf = UseConfig::Configuration.new :empty_conf,
      :empty => true
  end

  describe "#set_name" do
    it "changes name property" do
      @conf.set_name :empty_conf_changed
      @conf.instance_properties.name.should == 'empty_conf_changed'
    end

    it "doesn't change name when no parameter given" do
      expect {
        @conf.set_name
      }.should raise_error
    end
  end

  describe "#used_by_add" do
    it "adds the element" do
      @conf.used_by_add :class_one
      @conf.used_by.include?(:class_one).should == true
      @conf.used_by.count.should == 1
    end

    it "doesn't add the same element twice" do
      @conf.used_by_add :class_two
      @conf.used_by_add :class_two
      @conf.used_by.count.should == 1
    end

    it "adds two different elements" do
      @conf.used_by_add :class_three
      @conf.used_by_add :class_four
      @conf.used_by.count.should == 2
    end
  end

  describe "#used_by_drop" do
    it "removes the element" do
      @conf.used_by_add :class_five
      @conf.used_by_drop :class_five
      @conf.used_by.count.should == 0
    end

    it "doesn't remove anything if the key is unknown" do
      @conf.used_by_add :class_six
      @conf.used_by_drop :non_existing_class
      @conf.used_by.count.should == 1
    end
  end

  describe "#used_by" do
    it "returns used_by array" do
      @conf.used_by_add :class_seven
      @conf.used_by.should == [ :class_seven ]
    end
  end

  describe "#config_file_find" do
    it "finds the existing file" do
      @conf.set_name :first_conf
      @conf.config_file_find
      @conf.instance_properties.file.should_not == nil
    end

    it "doesn't find any non-existent file" do
      @conf.set_name :first_conf_missing
      @conf.config_file_find
      @conf.instance_properties.file.should == nil
    end
  end

  describe "#load_configuration" do
    it "loads configuration from the existing file" do
      @conf.set_name :first_conf
      @conf.config_file_find
      @conf.load_configuration
      @conf.core.name.should == 'first_conf'
    end

    it "doesn't load configuration if the file is missing" do
      @conf.name = :first_conf
      @conf.config_file = 'missing_file'
      @conf.load_configuration.should == false
    end
  end

  describe "#clear!" do
    it "clears itself" do
      @conf.qwerty = 'qwerty'
      @conf.asdfgh = 'asdfgh'
      @conf.clear!
      @conf.keys.should == []
    end
  end

  describe "#reload!" do
    context "when uses config file" do
      it "clears itself and loads configuration" do
        @conf.set_name :first_conf
        @conf.config_file_find
        @conf.load_configuration
        @conf.core.name = 'changed'
        @conf.reload!
        @conf.core.name.should == 'first_conf'
      end
    end

    context "when doesn't use config file" do
      it "clears itself" do
        @conf.core.name = 'changed'
        @conf.reload!
        @conf.keys.should == []
      end
    end
  end
end

describe UseConfig::Configuration, "class" do
  before :each do
    UseConfig::Configuration.reset!
    UseConfig::Configuration.configure do |c|
      c.path << "#{File.dirname(__FILE__)}/config"
    end
  end

  describe "general class behaivior" do
  end

  describe ".add_conf" do
    context "config file is not used" do
      before :each do
        UseConfig::Configuration.add_conf :some_class, :cfg,
          :empty => true
      end

      it "creates a new empty config hash" do
        UseConfig::Configuration.conf['cfg'].should == {}
      end

      it "hash values are accessible by methods" do
        UseConfig::Configuration.conf['cfg'].a_key = 'a_value'
        UseConfig::Configuration.conf['cfg'].a_key.should == 'a_value'
      end

      it "child hash values are accessinle by methods" do
        UseConfig::Configuration.conf['cfg'].one.two.three = 'a_value'
        UseConfig::Configuration.conf['cfg'].one.two.three == 'a_value'
      end

      it "keeps configuration when called the next time" do
        UseConfig::Configuration.conf['cfg'].a_key = 'a_value'
        UseConfig::Configuration.add_conf :another_class, :cfg,
          :empty => true
        UseConfig::Configuration.conf['cfg'].a_key.should == 'a_value'
      end
    end

    context "config file present" do
      before :each do
        UseConfig::Configuration.add_conf :some_class, :first_conf
        UseConfig::Configuration.add_conf :another_class, :second_conf
      end

      it "loads first configuration" do
        UseConfig::Configuration.conf['first_conf'].should_not == nil
      end

      it "loads second configuration" do
        UseConfig::Configuration.conf['second_conf'].should_not == nil
      end

      it "first configuration is correct" do
        UseConfig::Configuration.conf['first_conf'].core.name.should == 'first_conf'
      end

      it "second configuration is correct" do
        UseConfig::Configuration.conf['second_conf'].name.should == 'second_conf'
      end
    end

    context "config file missing" do
      it "raises error" do
        expect {
          UseConfig::Configuration.add_conf :some_class, :missing_conf
        }.to raise_error
      end
    end
  end

  describe ".drop_conf" do
    before :each do
      UseConfig::Configuration.add_conf :some_class, :cfg,
        :empty => true
    end

    context "configuration is used by a single class" do
      it "destroys configuration" do
        UseConfig::Configuration.drop_conf :some_class, :cfg
        UseConfig::Configuration.conf['cfg'].should == nil
      end
    end

    context "configuration is used by two classes" do
      it "keeps configuration when called once" do
        UseConfig::Configuration.add_conf :another_class, :cfg,
          :empty => true
        UseConfig::Configuration.drop_conf :some_class, :cfg
        UseConfig::Configuration.conf['cfg'].should_not == nil
      end

      it "destroys configuration when called a second time" do
        UseConfig::Configuration.add_conf :another_class, :cfg,
          :empty => true
        UseConfig::Configuration.drop_conf :some_class, :cfg
        UseConfig::Configuration.drop_conf :another_class, :cfg
        UseConfig::Configuration.conf['cfg'].should == nil
      end
    end
  end
end

