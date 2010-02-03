module Topical
  #Used in the forums, so i added a logged_in? method to alias authenticate in Clearance
  def logged_in?
    signed_in? || current_shop && has_shop?
  end
  # Used in creates and updates so customize to fit your app.
  #E.g., if you have two authenticated users whom can post in your forums, add their respective current_user type methods here.
  def posting_user
    current_user ? current_user.nickname : your_shop.nickname
  end
  #time support
  def time_ago_or_time_stamp(from_time, to_time = Time.now, include_seconds = true, detail = false)
    from_time = from_time.to_time if from_time.respond_to?(:to_time)
    to_time = to_time.to_time if to_time.respond_to?(:to_time)
    distance_in_minutes = (((to_time - from_time).abs)/60).round
    distance_in_seconds = ((to_time - from_time).abs).round
    case distance_in_minutes
      when 0..1           then time = (distance_in_seconds < 60) ? "#{distance_in_seconds} seconds ago" : '1 minute ago'
      when 2..59          then time = "#{distance_in_minutes} minutes ago"
      when 60..90         then time = "1 hour ago"
      when 90..1440       then time = "#{(distance_in_minutes.to_f / 60.0).round} hours ago"
      when 1440..2160     then time = '1 day ago' # 1-1.5 days
      when 2160..2880     then time = "#{(distance_in_minutes.to_f / 1440.0).round} days ago" # 1.5-2 days
      else time = from_time.strftime("%a, %d %b %Y")
    end
    return time_stamp(from_time) if (detail && distance_in_minutes > 2880)
    return time
  end
  
  def time_stamp(time)
    time.to_datetime.strftime("%a, %d %b %Y, %l:%M%P").squeeze(' ')  
  end
  
  def allow_editting
    unless logged_in? && posting_user.id == @message.nickname_id
      redirect_to root_path
      flash[:notice] = "You cannot use the feature you were trying to access."
    end    
  end
  
  #Allow the editting of an item.
  def can_edit?(current_item)
    return false unless logged_in?
    if request.path_parameters['controller'] == "users"
      return (current_user == current_item) 
    else
      return (posting_user.id == current_item.nickname_id) 
    end
  end
  #not really sure what this is...
  def can_edit
    redirect_to root_path and return false unless logged_in?
    klass = request.path_parameters['controller'].singularize.classify.constantize
    @item = klass.find(params[:id])
      redirect_to root_path and return false unless posting_user.id == @item.nickname_id
  end
end