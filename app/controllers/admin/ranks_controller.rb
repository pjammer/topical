class Admin::RanksController < ApplicationController
  before_filter :authenticate_area
  # before_filter :has_role_admin
  layout "static"
  # GET /ranks
  # GET /ranks.xml
  def index
    @ranks = Rank.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @ranks }
    end
  end

  # GET /ranks/1
  # GET /ranks/1.xml
  def show
    @rank =  Rank.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @rank }
    end
  end

  # GET /ranks/new
  # GET /ranks/new.xml
  def new
    @rank = Rank.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @rank }
    end
  end

  # GET /ranks/1/edit
  def edit
    @rank = Rank.find(params[:id])
  end

  # POST /ranks
  # POST /ranks.xml
  def create
    @rank = Rank.new(params[:rank])

    respond_to do |format|
      if @rank.save
        flash[:notice] = 'Rank was successfully created.'
        format.html { redirect_to([:admin, @rank]) }
        format.xml  { render :xml => @rank, :status => :created, :location => @rank }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @rank.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /ranks/1
  # PUT /ranks/1.xml
  def update
    @rank = Rank.find(params[:id])

    respond_to do |format|
      if @rank.update_attributes(params[:rank])
        flash[:notice] = 'Rank was successfully updated.'
        format.html { redirect_to([:admin, @rank]) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @rank.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /ranks/1
  # DELETE /ranks/1.xml
  def destroy
    @rank = Rank.find(params[:id])
    @rank.destroy

    respond_to do |format|
      format.html { redirect_to(admin_ranks_url) }
      format.xml  { head :ok }
    end
  end
end
