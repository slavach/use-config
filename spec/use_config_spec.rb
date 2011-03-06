require 'rubygems'
require 'rspec'

require File.dirname(__FILE__) + "/../lib/use_config.rb"

class Sample; include UseConfig; end

describe UseConfig do
  before :each do
    UseConfig::Configuration.reset!
    UseConfig::Configuration.configure do |c|
      c.path << "#{File.dirname(__FILE__)}/config"
    end
  end

  context "Sample class includes UseConfig" do
    it "has method use_config" do
      Sample.respond_to?(:use_config).should == true
    end

    it "has method drop_config" do
      Sample.respond_to?(:drop_config).should == true
    end

    it "uses configuration" do
      Sample.use_config :first_conf
      Sample.respond_to?(:first_conf).should == true
    end

    it "loads configuration" do
      Sample.use_config :first_conf
      Sample.first_conf.core.name.should == 'first_conf'
    end
  end

  context "Samle class instance" do
    before :each do
      Sample.use_config :first_conf
      @sample = Sample.new
    end

    it "has configuration accessor" do
      @sample.respond_to? :first_conf
    end

    it "has the actual configuration" do
      @sample.first_conf.core.name.should == 'first_conf'
    end
  end
end

