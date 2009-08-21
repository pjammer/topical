module ForumsHelper

  def members_online
    User.all :conditions => ["online_at >= ?", 10.minutes.ago]
  end
end
