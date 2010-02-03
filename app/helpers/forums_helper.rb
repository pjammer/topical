module ForumsHelper

  def members_online
    Nickname.all :conditions => ["online_at >= ?", 10.minutes.ago]
  end
end
