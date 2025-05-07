class CreateScreenshots < ActiveRecord::Migration[7.1]
  def change
    create_table :screenshots do |t|
      t.references :user, null: false, foreign_key: true
      t.string :file_path
      
      t.timestamps
    end
    
    add_index :screenshots, :created_at
  end
end