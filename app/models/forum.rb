class Forum < ActiveRecord::Base
  belongs_to :category
  has_many :topics
  has_many :messages
  has_one :last_topic, :class_name => "Topic", :order => "last_post_at desc"
end
