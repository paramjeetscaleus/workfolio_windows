class CreateWindowUsages < ActiveRecord::Migration[7.1]
  def change
    create_table :window_usages do |t|
      t.references :work_session, null: false, foreign_key: true
      t.string :window_title
      t.integer :duration
      t.float :percentage

      t.timestamps
    end
  end
end
