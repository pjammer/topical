class TopicsController < ApplicationController
  before_filter :load_topic, :except => [:index, :new, :create, :unknown_request]
  before_filter :find_forum, :except => [:index]
  before_filter :allow_editting, :only => [:edit, :destroy]
  #Implement post launch : view all forums link in Forums page.
  # def index
  #   @forum = current_account.forums
  #   if logged_in?      
  #     @topics = Topic.paginate(:page => params[:page], :include => [:user, :last_poster], :order => 'last_post_at desc')
  #   else
  #     @topics = Topic.paginate(:page => params[:page], :include => [:user, :last_poster], :order => 'last_post_at desc', :conditions => ["private = ?", false])
  #   end
  # end

  def show
    redirect_to login_path if (!logged_in? && @topic.private)
    @posts = @topic.messages.paginate(:page => params[:page], :include => :user)
    redirect_to @topic if @posts.blank? # if params[:page] is too big, no posts will be found
    @page = params[:page] ? params[:page] : 1
    @previous_topic = @topic.previous
    @next_topic = @topic.next
    @padding = ((@page.to_i - 1) * Topic::PER_PAGE) # to get post #s w/ pagination
    @topic.hit!
  end

  def new
    @topic = @forum.topics.new
    @forum = Forum.find_by_id(:forum_id)

  end

  def create
    
    @topic = current_user.topics.build(params[:topic])
    @post = @topic.messages.build(params[:topic]) 
    @post.user = current_user
    @topic.forum_id = @forum.id
    redirect_to forum_topic_url(@topic.forum_id, @topic) and return if @topic.save && @post.save
    @new_topic = @topic; render :action => "new"
  end

  def edit

  end

  def update
    if @topic.update_attributes(params[:topic])
      redirect_to @topic
    else
      render :action => "edit"
    end
  end

  def destroy
    @topic.destroy
    redirect_to forum_topics_url
  end
    
  def show_new
    redirect_to forum_topic_path(:id => params[:id]) and return if @topic.messages_count == 1 # if the first post, see it from the top of the page
    @post = @topic.messages.find(:first, :order => 'created_at asc', :conditions => ["created_at >= ?", session[:online_at]]) unless !logged_in?
    @post = Message.find(@topic.last_post_id) if @post.nil?
    redirect_to :controller => 'topics', :action => 'show', :id => @topic.id, :page => @post.page, :anchor => 'p' + @post.id.to_s
  end
  
  def show_posters
    @posters = @topic.mesesages.map(&:user) ; @posters.uniq!
    render :update do |page| 
      page.toggle :posters
      page.replace_html 'posters', "#{@posters.map { |u| "#{h u.login}" } * ', ' }" 
    end 
  end
  
  def unknown_request
    if request.request_uri.include?('viewtopic.php') # catch punbb-style urls
      if params[:id].blank? # punbb can show a topic based on the post_id being passed as "pid"
        @post = Post.find(params[:pid]) # if this is the case, get the post info
        params[:id] = @post.topic_id # set the regular topic_id value as id with this post's topic_id
      end
      redirect_to forum_topic_path(:id => params[:id], :anchor => params[:anchor])
    elsif request.request_uri.include?('action=show_new') # legacy url format from punbb
      redirect_to forum_topics_path
    else
      redirect_to root_path
    end
  end
  def load_topic
    @topic = Topic.find(params[:id])
  end
  def find_forum
    @forum = Forum.find_by_id(params[:forum_id])
  end
end
