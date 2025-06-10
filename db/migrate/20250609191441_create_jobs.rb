class CreateJobs < ActiveRecord::Migration[8.0]
  def change
    create_table :jobs do |t|
      t.string :title, null: false
      t.decimal :hourly_salary, null: false, precision: 8, scale: 2

      t.timestamps
    end
  end
end
