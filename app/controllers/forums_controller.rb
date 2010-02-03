class ForumsController < ApplicationController
  unloadable
  before_filter :load_forum, :only => [:show]
  layout "static"
  # GET /forums
  # GET /forums.xml
  def index
    @categories = Category.all
    @messages_count = Forum.sum('messages_count')
    @topics_count = Forum.sum('topics_count')
    @forum = Forum.find(:all)
  end

  # GET /forums/1
  # GET /forums/1.xml
  
  def show
    @topic = Topic.new ; @topic.forum_id = @forum.id # set forum_id for new topic select default option
    if logged_in?
      @topics = Topic.paginate(:page => params[:page], :include => [:nickname, :last_poster], :order => 'last_post_at desc', :conditions => ["forum_id = ?", @forum.id])
    else
      @topics = Topic.paginate(:page => params[:page], :include => [:nickname, :last_poster], :order => 'last_post_at desc', :conditions => ["forum_id = ? and private = ?", @forum.id, false])
    end
    render(:template => "topics/index")
  end
  protected
  #loads forum first and then uses it in account_forums_only
  def load_forum
     @forum = Forum.find(params[:id], :include => :category)
  end
end
