# This file contains unit tests for the User model.
# These tests ensure that the User model's validations and
# functionalities (like password hashing and role enums) work correctly
# in isolation, without hitting the controller or routes.

require 'rails_helper'

RSpec.describe User, type: :model do
  # --- Validations ---
  describe 'validations' do
    it 'is valid with valid attributes' do
      user = User.new(name: "Test User", email: "test@example.com", password: "password", role: :user)
      expect(user).to be_valid
    end

    it 'is valid with a name' do
      user = User.new(name: 'Test User', email: "test@example.com", password: 'password')
      expect(user).to be_valid
    end

    it 'is invalid without a name' do
      user = User.new(name: nil, email: "test@example.com", password: "password", role: :user)
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("can't be blank")
    end

    it 'is invalid without an email' do
      user = User.new(name: "Test User", email: nil, password: "password", role: :user)
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it 'is invalid with a duplicate email (case-insensitive)' do
      User.create!(name: "Existing User", email: "duplicate@example.com", password: "password", role: :user)
      user = User.new(name: "Another User", email: "Duplicate@example.com", password: "another_password", role: :user)
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("has already been taken")
    end

    it 'is invalid with an invalid email format' do
      user = User.new(name: "Invalid User", email: "invalid-email", password: "password", role: :user)
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("is not a valid email format")
    end

    it 'is valid with a valid email format' do
      user = User.new(name: "Valid User", email: "valid@example.com", password: "password", role: :user)
      expect(user).to be_valid
    end

    it 'is invalid without a password' do
      user = User.new(name: "Test User", email: "test_no_pass@example.com", password: nil, role: :user)
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("can't be blank")
    end

    it 'is invalid with a password less than 6 characters' do
      user = User.new(name: "Test User", email: "test_short_pass@example.com", password: "123", role: :user)
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("is too short (minimum is 6 characters)")
    end
  end

  # --- Roles ---
  describe 'roles' do
    it 'sets role to user by default' do
      user = User.create!(name: "Default User", email: "default@example.com", password: "password")
      expect(user.user?).to be_truthy
      expect(user.role).to eq('user')
    end

    it 'can set role to admin' do
      user = User.create!(name: "Admin User", email: "admin@example.com", password: "password", role: :admin)
      expect(user.admin?).to be_truthy
      expect(user.role).to eq('admin')
    end

    it 'has correct enum values' do
      expect(User.roles[:user]).to eq(0)
      expect(User.roles[:admin]).to eq(1)
    end
  end

  # --- Authentication ---
  describe '#authenticate' do
    let(:user) { User.create!(name: "Auth User", email: "auth@example.com", password: "correctpassword") }

    it 'returns the user if password is correct' do
      authenticated_user = user.authenticate("correctpassword")
      expect(authenticated_user).to eq(user)
    end

    it 'returns false if password is incorrect' do
      authenticated_user = user.authenticate("wrongpassword")
      expect(authenticated_user).to be_falsey
    end
  end
end
