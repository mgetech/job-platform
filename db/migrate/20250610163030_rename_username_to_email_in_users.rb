class RenameUsernameToEmailInUsers < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    if index_exists?(:users, :username, name: 'index_users_on_username')
      remove_index :users, :username, name: 'index_users_on_username'
    end

    rename_column :users, :username, :email

    add_index :users, :email, unique: true, name: 'index_users_on_email_unique', algorithm: :concurrently
  end
end
