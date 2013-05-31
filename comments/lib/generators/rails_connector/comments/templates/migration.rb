class CreateComments < ActiveRecord::Migration
  def self.up
    create_table :comments do |t|
      t.string :obj_id
      t.string :name
      t.string :email
      t.string :subject
      t.text :body
      t.datetime :created_at
    end
  end

  def self.down
    drop_table :comments
  end
end
