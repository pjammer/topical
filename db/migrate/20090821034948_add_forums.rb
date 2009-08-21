class AddForums < ActiveRecord::Migration
  def self.up
    create_table :forums, :force => true do |t|
      t.integer :category_id
      t.string :name, :description
      t.integer  :topics_count,   :default => 0
      t.integer  :messages_count, :default => 0
      t.integer  :position,       :default => 0
      t.timestamps
    end
    add_index :forums, [:category_id], :name => "index_forums_on_category_id"
    add_index :forums, [:category_id], :name => "index_forums_on_last_post_at"
  end

  def self.down
    remove_index :forums, :name => :index_forums_on_last_post_at
    remove_index :forums, :name => :index_forums_on_category_id
    drop_table :forums
  end
end
