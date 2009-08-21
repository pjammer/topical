class AddMessages < ActiveRecord::Migration
  def self.up
    create_table :messages, :force => true do |t|
      t.integer :forum_id, :user_id, :topic_id, :updated_by
      t.string :type, :title
      t.text :content
      t.timestamps
    end
  end

  def self.down
    drop_table :messages
  end
end
