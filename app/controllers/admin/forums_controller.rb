class Admin::ForumsController < ApplicationController
 before_filter :login_required
 before_filter :has_role_admin
 layout "admin"
  # GET /forums
  # GET /forums.xml
  def index
    @categories = Category.find_all_by_account_id(current_account.id)
    @messages_count = Forum.sum('messages_count')
    @topics_count = Forum.sum('topics_count')
  end

  # GET /forums/new
  # GET /forums/new.xml
  def new
    @forum = Forum.new
     @all_categories = Category.find_all_by_account_id(current_account.id, :order => "name") 
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @forum }
    end
  end

  # GET /forums/1/edit
  def edit
    @forum = Forum.find(params[:id])
  end

  # POST /forums
  # POST /forums.xml
  def create
    @forum = Forum.new(params[:forum])

    respond_to do |format|
      if @forum.save
        flash[:notice] = 'Forum was successfully created.'
        format.html { redirect_to admin_forums_path }
        format.xml  { render :xml => @forum, :status => :created, :location => @forum }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @forum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /forums/1
  # PUT /forums/1.xml
  def update
    @forum = Forum.find(params[:id])

    respond_to do |format|
      if @forum.update_attributes(params[:forum])
        flash[:notice] = 'Forum was successfully updated.'
        format.html { redirect_to([:admin, @forum]) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @forum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /forums/1
  # DELETE /forums/1.xml
  def destroy
    @forum = Forum.find(params[:id])
    @forum.destroy

    respond_to do |format|
      format.html { redirect_to(admin_forums_url) }
      format.xml  { head :ok }
    end
  end
end