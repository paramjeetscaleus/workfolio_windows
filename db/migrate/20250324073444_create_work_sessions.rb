class CreateWorkSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :work_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.datetime :clock_in
      t.datetime :break_start
      t.datetime :break_end
      t.datetime :clock_out
      t.float :total_hours

      t.timestamps
    end
  end
end
