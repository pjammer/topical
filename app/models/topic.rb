class Topic < ActiveRecord::Base
    has_many :messages, :order => 'messages.created_at', :dependent => :destroy 
    has_many :posters, :through => :messages, :source => :user, :uniq => true
    belongs_to :user
    belongs_to :forum, :counter_cache => true
    belongs_to :last_post, :foreign_key => "last_post_id", :class_name => "Message"
    belongs_to :last_poster, :foreign_key => "last_post_by", :class_name => "User"

    validates_presence_of :user_id, :title

    acts_as_ordered :order => 'last_post_id'

    attr_accessor :content
    named_scope :listing, :include => [:user, :last_poster], :order =>"last_post_at desc", :limit => 6
    # attr_accessible :title, :private, :locked, :sticky, :forum_id, :body

    PER_PAGE = 15

    def hit!
      self.class.increment_counter :views, id
    end

    def posters
      messages.map { |p| p.user_id }.uniq.size
    end

    def updated_at
      last_post_at
    end

    def replies 
      self.messages_count - 1
    end

    def last_page
      [(messages_count.to_f / PER_PAGE).ceil.to_i, 1].max
    end

    def update_cached_fields
      message = messages.find(:first, :order => 'messages.created_at desc')
      return if message.nil? # return if this was the last post in the thread
      self.class.update_all(['last_post_id = ?, last_post_at = ?, last_post_by = ?', message.id, message.created_at, message.user_id], ['id = ?', self.id])
    end

    def to_s
      title.to_s
    end

  end
