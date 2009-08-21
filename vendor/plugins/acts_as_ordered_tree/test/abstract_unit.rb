
ENV["RAILS_ENV"] = "test"
require File.dirname(__FILE__) + '/../../../../config/environment'
require 'test_help'

config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + '/debug.log')
ActiveRecord::Base.establish_connection(config['database'])

require File.dirname(__FILE__) + '/../lib/acts_as_ordered_tree'
ActiveRecord::Base.send(:include, WizardActsAsOrderedTree::Acts::OrderedTree)

require File.dirname(__FILE__) + '/../lib/person'

load(File.dirname(__FILE__) + '/schema.rb')
