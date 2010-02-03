class AddTopics < ActiveRecord::Migration
  def self.up
    create_table :topics, :force => true do |t|
      t.integer :forum_id, :nickname_id, :last_post_id, :last_post_by
      t.string :type, :title 
      t.text :content
      t.integer  :views,          :default => 0
      t.integer  :messages_count, :default => 0 
      t.datetime :last_post_at
      t.boolean  :private,        :default => false
      t.boolean  :locked
      t.boolean  :sticky,         :default => false
      t.timestamps
    end
    add_index :topics, [:forum_id], :name => "index_topics_on_forum_id"
    add_index :topics, [:forum_id, :last_post_at], :name => "index_topics_on_last_post_at"
  end

  def self.down
    remove_index :topics, :name => :index_topics_on_forum_id
    remove_index :topics, :name => :index_topics_on_last_post_at
    drop_table :topics
  end
end
