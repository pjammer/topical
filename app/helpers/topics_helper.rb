module TopicsHelper
  def random_string
    char = ("a".."z").to_a + ("1".."9").to_a
    Array.new(6, '').collect{char[rand(char.size)]}.join
  end
  def rank_for(user)
   # return 'Administrator' if user.admin
   @ranks ||=  Rank.find(:all, :order => "min_posts")
   return "Member" if @ranks.blank?
   for r in @ranks
     @rank = r if user.messages_count >= r.min_posts
   end
   return h(@rank.title)
 end
 
 def bb(text)
   text = simple_format(bbcodeize(sanitize(h(text))))
   auto_link(text) do |t|
     truncate(t, 50)
   end
 end
end