require 'rspec'

#require File.dirname(__FILE__) + "/../../hash-access/lib/hash_access.rb"
require File.dirname(__FILE__) + "/../lib/use_config.rb"

class UseConfigDemo
  include UseConfig
end

describe UseConfig::Configuration do
  pending "Tests are not yet written"
end

describe UseConfig do
  pending "Tests are not yet written"
end

describe UseConfigDemo, "demo class for testing" do
  pending "Tests are not yet written"
end

