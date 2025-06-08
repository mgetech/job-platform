class User < ApplicationRecord
  has_secure_password

  enum :role, { user: 0, admin: 1 }

  validates :name, presence: true
  validates :username, presence: true, uniqueness: true
end