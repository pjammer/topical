module ForumsHelper

  def members_online
    User.all :conditions => ["online_at >= ? and memberships.account_id = ?", 10.minutes.ago, current_account.id], :include => [:memberships]
  end
end
