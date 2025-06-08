# This file contains unit tests for the User model.
# These tests ensure that the User model's validations and
# functionalities (like password hashing and role enums) work correctly
# in isolation, without hitting the controller or routes.

require 'rails_helper'

RSpec.describe User, type: :model do

  # --- Validations ---
  describe 'validations' do
    # Test for presence of 'name'
    it 'is valid with a name' do
      user = User.new(name: 'Test User', username: 'testuser', password: 'password')
      expect(user).to be_valid # Expect the user to be valid if name is present
    end

    it 'is invalid without a name' do
      user = User.new(name: nil, username: 'testuser', password: 'password')
      expect(user).not_to be_valid # Expect the user to be invalid if name is missing
      expect(user.errors[:name]).to include("can't be blank") # Check specific error message
    end

    # Test for presence of 'username'
    it 'is valid with a username' do
      user = User.new(name: 'Test User', username: 'testuser', password: 'password')
      expect(user).to be_valid
    end

    it 'is invalid without a username' do
      user = User.new(name: 'Test User', username: nil, password: 'password')
      expect(user).not_to be_valid
      expect(user.errors[:username]).to include("can't be blank")
    end

    # Test for uniqueness of 'username'
    it 'is invalid with a duplicate username' do
      User.create!(name: 'Existing User', username: 'existinguser', password: 'password') # Create an existing user
      user = User.new(name: 'New User', username: 'existinguser', password: 'anotherpassword') # Try to create one with same username
      expect(user).not_to be_valid
      expect(user.errors[:username]).to include("has already been taken")
    end

    # Test for password presence (handled by has_secure_password indirectly)
    it 'is invalid without a password' do
      user = User.new(name: 'Test User', username: 'testuser', password: nil)
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("can't be blank")
    end
  end

  # --- has_secure_password functionality ---
  describe 'password authentication' do
    let(:user) { User.create!(name: 'Auth User', username: 'authuser', password: 'securepassword') }

    it 'authenticates with a correct password' do
      # The 'authenticate' method is provided by has_secure_password
      expect(user.authenticate('securepassword')).to eq(user)
    end

    it 'does not authenticate with an incorrect password' do
      expect(user.authenticate('wrongpassword')).to be_falsey # be_falsey matches false or nil
    end
  end

  # --- Enum for roles ---
  describe 'role enum' do
    let(:user_role_user) { User.create!(name: 'Standard User', username: 'stduser', password: 'password', role: :user) }
    let(:user_role_admin) { User.create!(name: 'Admin User', username: 'admuser', password: 'password', role: :admin) }

    it 'correctly assigns the default role' do
      new_user = User.new(name: 'Default Role', username: 'defaultrole', password: 'password')
      new_user.save # Save to trigger default
      expect(new_user.role).to eq('user')
      expect(new_user.user?).to be_truthy
    end

    it 'correctly assigns the admin role' do
      expect(user_role_admin.role).to eq('admin')
      expect(user_role_admin.admin?).to be_truthy
    end

    it 'responds to role predicate methods' do
      expect(user_role_user.user?).to be_truthy
      expect(user_role_user.admin?).to be_falsey
      expect(user_role_admin.admin?).to be_truthy
      expect(user_role_admin.user?).to be_falsey
    end
  end
end
