require 'rails_helper'

RSpec.describe 'Authentication', type: :request do
  # --- POST /register ---
  describe 'POST /register' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          name: 'John Doe',
          email: 'john.doe@example.com',
          password: 'password123'
        }
      end

      it 'creates a new user and returns a token' do
        expect {
          post '/register', params: valid_params
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['token']).to be_present
        expect(json_response['role']).to eq('user') # Ensure default role is user
      end

      it 'does not allow setting an admin role during registration' do
        post '/register', params: { name: 'Admin Wannabe', email: 'admin.wannabe@example.com', password: 'password123', role: 'admin' }
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['role']).to eq('user')
        expect(User.last.admin?).to be_falsey
      end
    end

    context 'with invalid parameters' do
      it 'returns unprocessable entity for missing email' do
        post '/register', params: { name: 'Jane Doe', email: nil, password: 'password123' }
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include("Email can't be blank")
      end

      it 'returns unprocessable entity for duplicate email' do
        User.create!(name: 'Existing User', email: 'existing@example.com', password: 'password')
        post '/register', params: { name: 'New User', email: 'existing@example.com', password: 'new_password' }
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include("Email has already been taken")
      end

      it 'returns unprocessable entity for missing password' do
        post '/register', params: { name: 'Jane Doe', email: 'jane.doe@example.com', password: nil }
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include("Password can't be blank")
      end

      it 'returns unprocessable entity for missing name' do
        post '/register', params: { name: nil, email: 'jane.doe@example.com', password: 'password123' }
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include("Name can't be blank")
      end
    end
  end

  # --- POST /login ---
  describe 'POST /login' do
    let!(:user) { User.create!(name: "Test User", email: "test@example.com", password: "correctpassword", role: :user) }
    let!(:admin_user) { User.create!(name: "Admin User", email: "admin@example.com", password: "adminpassword", role: :admin) }

    context 'with valid credentials' do
      it 'returns a token for a regular user' do
        post '/login', params: { email: 'test@example.com', password: 'correctpassword' }
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['token']).to be_present
        expect(json_response['role']).to eq('user')

        # Optionally, decode the token to ensure it contains the correct user_id
        decoded_token = JsonWebToken.decode(json_response['token'])
        expect(decoded_token).to have_key('user_id')
        expect(decoded_token['user_id']).to eq(user.id)
      end

      it 'returns a token for an admin user' do
        post '/login', params: { email: 'admin@example.com', password: 'adminpassword' }
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['token']).to be_present
        expect(json_response['role']).to eq('admin')
      end
    end

    context 'with invalid credentials' do
      it 'returns unauthorized for incorrect password' do
        post '/login', params: { email: 'test@example.com', password: 'wrongpassword' }
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid credentials')
      end

      it 'returns unauthorized for non-existent email' do
        post '/login', params: { email: 'nonexistent@example.com', password: 'anypassword' }
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid credentials')
      end
    end
  end
end