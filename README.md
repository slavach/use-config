# UseConfig

Easy configuration solution for any Ruby class.

[UseConfig](https://github.com/slavach/use-config) allows a Ruby class to use
configuration stored in a YAML file.

Configuration is loaded by a single line of code, like:

    use_config :conf

Once been loaded, configuration values are accessible by calling to the
corresponding methods:

    conf.project.name

## Installation

UseConfig is available as the gem use-config.

    gem ins use-config

## Usage Example

First, create the configuration file conf.yaml, containing a hash
representation:

    project:
      name: use-config-demo
      title: UseConfig Demo Project

    messages:
      welcome: Welcome to the UseConfig Demo
      lorem: Lorem ipsum dolor sit amet, consectetur adipisicing elit

Next, create a ruby program that uses the above configuration:

    require 'use_config'
    include UseConfig

    class UseConfigDemo
      use_config :conf # Creates a hash accessible by the 'conf' method

      def show_project
        print 'Name: ', conf.project.name, "\n"
        print 'Title: ', conf.project.title, "\n"
      end
    end

    demo = UseConfigDemo.new

    demo.show_project

    print demo.conf.messages.welcome, "\n"
    print demo.conf.messages.lorem, "\n"

## Development

Clone the latest code from Github:

    git clone git://github.com/slavach/use-config.git

Install bundler:

    gem install bundler

Install required gems:

    bundle install

To invoke tests - run `rake spec` or simply `rake`.

## Author

HashAccess has been written by Svetoslav Chernobay <slava@chernobay.info>.
Feel free to contact him if you have any questions or comments.

