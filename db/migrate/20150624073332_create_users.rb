class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
    	t.column :first_name,:string
    	t.column :last_name,:string
    	t.column :login,:string, :primary => true
    	t.column :email,:string
        t.column :authority, :integer
    	t.column :salt,:string
    	t.column :password_digest, :string
    end
  end
end
