class CreateNicknames < ActiveRecord::Migration
  def self.up
    create_table :nicknames do |t|
      t.string :name
      t.integer :nameable_id
      t.string :nameable_type
      t.integer :messages_count, :default => 0
      t.timestamps
    end
  end

  def self.down
    drop_table :nicknames
  end
end
