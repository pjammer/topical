class ForumsController < ApplicationController
  before_filter :load_forum, :only => [:show]
  before_filter :account_forums_only, :only => [:show]
  # GET /forums
  # GET /forums.xml
  def index
    @categories = current_account.categories
    @messages_count = current_account.forums.sum('messages_count')
    @topics_count = current_account.forums.sum('topics_count')
    @forum = Forum.find(:all)
  end

  # GET /forums/1
  # GET /forums/1.xml
  
  def show
    @topic = Topic.new ; @topic.forum_id = @forum.id # set forum_id for new topic select default option
    if logged_in?
      @topics = Topic.paginate(:page => params[:page], :include => [:user, :last_poster], :order => 'last_post_at desc', :conditions => ["forum_id = ?", @forum.id])
    else
      @topics = Topic.paginate(:page => params[:page], :include => [:user, :last_poster], :order => 'last_post_at desc', :conditions => ["forum_id = ? and private = ?", @forum.id, false])
    end
    render(:template => "topics/index")
  end
  protected
  #loads forum first and then uses it in account_forums_only
  def load_forum
     @forum = Forum.find(params[:id], :include => :category)
  end
  def account_forums_only
    unless @forum.category_id === Category.find_by_account_id(current_account.id).id
      flash[:notice] = "Not your forum"
      redirect_to root_url
    end
  end
end
