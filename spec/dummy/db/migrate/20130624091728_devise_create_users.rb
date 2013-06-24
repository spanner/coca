class DeviseCreateUsers < ActiveRecord::Migration
  def change
    create_table(:users) do |t|
      t.string :name
      t.string :uid

      ## Database authenticatable
      t.string :email,              :null => false, :default => ""
      t.string :encrypted_password, :null => false, :default => ""

      ## Token authenticatable
      t.string :authentication_token

      t.timestamps
    end
    
    add_index :users, :email
    add_index :users, :uid
    add_index :users, :authentication_token

  end
end
