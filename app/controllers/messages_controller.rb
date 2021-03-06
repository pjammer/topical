class MessagesController < ApplicationController 
  unloadable
  before_filter :find_topic_and_message, :except => [:new, :create]

  before_filter :can_edit, :only => [:edit, :update, :destroy]
  
  def index
    redirect_to forum_topics_path
  end
  
  def show
    @message = Message.find(params[:id])
  end
  
  def new
  end

  def create
    @topic = Topic.find(params[:message][:topic_id])
    redirect_home unless @topic
    @message = posting_user.messages.build(params[:message])
    if @topic.locked
      redirect_to root_path and return false unless has_role_admin || (posting_user == @topic.nickname)
    end
    @topic.messages_count += 1 # hack to set last_page correctly
    if (@topic.messages << @message) 
      redirect_to :controller => 'topics', :action => 'show', :id => @topic.id, :page => @topic.last_page, :anchor => 'p' + @message.id.to_s
    else 
      flash[:notice] = "Messages cannot be blank"
      redirect_to @topic
    end 
  end
  
  def edit
  end 
    
  def update 
    @message.updated_by = posting_user.id
    if @message.update_attributes(params[:message]) 
      redirect_to topic_message_path(@message)
    else 
      render :action => :edit 
    end 
  end 

  def destroy 
    @message.destroy if @topic.messages_count > 1
    redirect_to show_new_forum_topic_path(@topic)
  end 
  
  def topic
    redirect_to :controller => 'topics', :action => 'show', :id => @topic.id, :page => @message.page, :anchor => 'p' + @message.id.to_s
  end
  
  def quote
    @content = "[quote=#{@message.nickname[:name]}]#{@message.content}[/quote]"
    @message = nil # clear message so form with create a new one
    render :template => "messages/new"
  end
      
  def find_topic_and_message
    @message = Message.find(params[:id])
    @topic = Topic.find(@message.topic.id)
    redirect_to forum_topics_url unless @topic
  end 
      
end
