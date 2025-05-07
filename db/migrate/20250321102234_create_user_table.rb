class CreateUserTable < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :encrypted_password 
      t.string :phone_number
      t.string :address
      t.string :city
      t.string :state
      t.string :country
      t.string :zip_code
      t.string :role
      t.timestamps
    end
  end
end
