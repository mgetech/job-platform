class User < ApplicationRecord
  has_secure_password

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP, message: "is not a valid email format" }
  validates :password, presence: true, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }

  enum :role, { user: 0, admin: 1 }
end