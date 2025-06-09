require 'rails_helper'

RSpec.describe 'Authentication', type: :request do
  describe 'POST /register' do
    context 'with valid parameters' do
      it 'registers a new user and returns a token' do
        post '/register', params: { name: 'John Doe', username: 'johndoe_reg', password: 'password123' }
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('token')
        expect(json_response['token']).not_to be_empty
        expect(json_response['role']).to eq('user') # Verify default role
        expect(User.last.username).to eq('johndoe_reg') # Verify user creation in DB
      end

      it 'does not allow setting an admin role during registration' do
        post '/register', params: { name: 'Admin Wannabe', username: 'adminwannabe', password: 'password123', role: 'admin' }
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['role']).to eq('user') # Should still be user, not admin
        expect(User.last.admin?).to be_falsey # Ensure role is not admin in DB
      end
    end

    context 'with invalid parameters' do
      it 'returns unprocessable entity without a name' do
        post '/register', params: { username: 'testuser', password: 'password' }
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include("Name can't be blank")
      end

      it 'returns unprocessable entity without a username' do
        post '/register', params: { name: 'John Doe', password: 'password' }
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include("Username can't be blank")
      end

      it 'returns unprocessable entity with a duplicate username' do
        User.create!(name: 'Existing User', username: 'duplicateuser', password: 'password')
        post '/register', params: { name: 'New User', username: 'duplicateuser', password: 'password' }
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include("Username has already been taken")
      end

      it 'returns unprocessable entity without a password' do
        post '/register', params: { name: 'John Doe', username: 'nopassword' }
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include("Password can't be blank")
      end
    end
  end

  describe 'POST /login' do
    let!(:user) { User.create!(name: 'Jane Doe', username: 'janedoe_login', password: 'password123') }

    context 'with valid credentials' do
      it 'authenticates the user and returns a token' do
        post '/login', params: { username: 'janedoe_login', password: 'password123' }
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('token')
        expect(json_response['token']).not_to be_empty
        expect(json_response['role']).to eq('user')

        # Optionally, decode the token to ensure it contains the correct user_id
        decoded_token = JsonWebToken.decode(json_response['token'])
        expect(decoded_token).to have_key('user_id')
        expect(decoded_token['user_id']).to eq(user.id)
      end
    end

    context 'with invalid credentials' do
      it 'rejects incorrect password' do
        post '/login', params: { username: 'janedoe_login', password: 'wrongpassword' }
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid credentials')
      end

      it 'rejects non-existent username' do
        post '/login', params: { username: 'nonexistent', password: 'password123' }
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid credentials')
      end

      it 'rejects missing username' do
        post '/login', params: { password: 'password123' }
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid credentials')
      end

      it 'rejects missing password' do
        post '/login', params: { username: 'janedoe_login' }
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid credentials')
      end
    end
  end
end