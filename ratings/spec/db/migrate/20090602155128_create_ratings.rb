class CreateRatings < ActiveRecord::Migration
  def self.up
    create_table :ratings do |t|
      t.timestamps
      t.column :obj_id, :string
      t.column :score, :integer
      t.column :count, :integer, :default => 0
    end
  end

  def self.down
    drop_table :ratings
  end
end
