class Nickname < ActiveRecord::Base
  #Remove after you have done the following:
  #You are going to want to add the nickname partial in app/views/nickname/nickname_form.html.erb
  #To your User type model's New action. (we use arg , so pass a :locals => {:arg => @user})  Your "@user" may vary however.
  # Also ensure your User Model is using  accepts_nested_attributes_for as seen in the example below:
  #-------------------------------------
  # class User < ActiveRecord::Base
  #   
  #   has_many :topics, :through => :nickname
  #   has_one :nickname, :as => :nameable
  #   has_many :messages, :through => :nickname
  #   
  #   attr_accessible :nickname_attributes
  #   accepts_nested_attributes_for :nickname, :allow_destroy => true 
  # 
  # end
  #-------------------------------------
  
  belongs_to :nameable, :polymorphic => true
  has_many :messages
  has_many :topics
  
  validates_uniqueness_of :name
  validates_presence_of :name

end
