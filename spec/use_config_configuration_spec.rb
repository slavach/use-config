require 'rubygems'
require 'rspec'

require File.dirname(__FILE__) + "/../lib/use_config/configuration.rb"

describe UseConfig::Configuration, "class" do
  describe "the class itself is a container for instances" do

    pending
  end

  describe ".add_conf should create a new config hash" do
    context "config file is not used" do
      it "creates a new config hash" do
        UseConfig::Configuration.add_conf :some_class, :cfg, :empty => 1
        UseConfig::Configuration.conf['cfg'].should_not == nil
      end

      it "configuration hash is empty" do
        UseConfig::Configuration.add_conf :some_class, :cfg, :empty => 1
        UseConfig::Configuration.conf['cfg'].should == {}
      end

      it "hash values are accessible by methods" do
        UseConfig::Configuration.add_conf :some_class, :cfg, :empty => 1
        UseConfig::Configuration.conf['cfg'].a_key = 'a_value'
        UseConfig::Configuration.conf['cfg'].a_key.should == 'a_value'
      end

      it "hash children are accessinle by methods" do
        UseConfig::Configuration.add_conf :some_class, :cfg, :empty => 1
        UseConfig::Configuration.conf['cfg'].one.two.three = 'a_value'
        UseConfig::Configuration.conf['cfg'].one.two.three == 'a_value'
      end
    end

    context "config file present" do
      it "creates configuration" do
      end
    end

    context "config file missing" do
      it "raises error" do
        expect {
          UseConfig::Configuration.add_conf :class_file, :cfg_missing
        }.to raise_error
      end
    end
  end
end

