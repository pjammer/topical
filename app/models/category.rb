class Category < ActiveRecord::Base
  belongs_to :categorical, :polymorphic => :true
  has_many :forums
  validates_presence_of     :name, :position
  validates_uniqueness_of   :name, :case_sensitive => false
  def to_s
    name.to_s
  end
end
