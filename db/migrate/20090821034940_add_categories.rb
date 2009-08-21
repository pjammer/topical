class AddCategories < ActiveRecord::Migration
  def self.up
    create_table :categories, :force => true do |t|
      t.string :name, :categorical_type
      t.integer :position, :categorical_id      
      t.timestamps
    end
  end

  def self.down
    drop_table :categories
  end
end
