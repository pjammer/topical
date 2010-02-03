class Rank < ActiveRecord::Base
  belongs_to :account
  attr_accessible :title, :min_posts
  
  validates_presence_of :title, :min_posts
  validates_uniqueness_of :title, :min_posts
  validates_numericality_of :min_posts
end
