class CreateBewerbungen < ActiveRecord::Migration[8.0]
  def change
    create_table :bewerbungen do |t|
      t.references :user, null: false, foreign_key: true
      t.references :job, null: false, foreign_key: true

      t.timestamps
    end

    add_index :bewerbungen, [:user_id, :job_id], unique: true
  end
end
