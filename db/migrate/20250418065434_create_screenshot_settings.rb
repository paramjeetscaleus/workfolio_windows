class CreateScreenshotSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :screenshot_settings do |t|
      t.integer :user_id
      t.integer :interval

      t.timestamps
    end
  end
end
