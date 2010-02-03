class AddRanks < ActiveRecord::Migration
  def self.up
    create_table :ranks, :force => true do |t|
      t.string   :title
      t.integer  :min_posts
      t.timestamps
    end
  end

  def self.down
    drop_table :ranks
  end
end