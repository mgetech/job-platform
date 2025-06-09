class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :username, null: false, index: { unique: true }
      t.string :password_digest
      t.integer :role, default: 0  # 0 = user, 1 = admin

      t.timestamps
    end
  end
end
