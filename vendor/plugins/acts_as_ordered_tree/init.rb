require File.dirname(__FILE__) + '/lib/acts_as_ordered_tree'
ActiveRecord::Base.send(:include, WizardActsAsOrderedTree::Acts::OrderedTree)
