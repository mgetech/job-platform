require 'swagger_helper'

RSpec.describe 'Authentication API', type: :request do

  # --- POST /register ---
  path '/register' do
    post 'Creates a new user account' do
      tags 'Authentication'
      consumes 'application/json'

      parameter name: :user, in: :body, schema: {
                                                  type: :object,
                                                  properties: {
                                                    name: { type: :string, description: 'User\'s full name' },
                                                    email: { type: :string, format: 'email', description: 'User\'s email address (must be unique)' },
                                                    password: { type: :string, format: 'password', description: 'User\'s password (minimum 6 characters)' }
                                                  },
                                                  required: %w[name email password]
      }, description: 'User registration details'

      response '201', 'user created and token returned' do
        let(:user) { { name: 'John Doe', email: 'john.doe@example.com', password: 'password123' } }
        schema type: :object,
               properties: {
                 token: { type: :string, description: 'JWT authentication token' },
                 role: { type: :string, enum: ['user', 'admin'], description: 'Role of the newly created user' }
               },
               required: %w[token role]

        run_test! do |response|
          expect(response).to have_http_status(:created)
          json_response = JSON.parse(response.body)
          expect(json_response['token']).to be_present
          expect(json_response['role']).to eq('user')
        end
      end

      response '422', 'invalid registration parameters' do
        let(:user) { { name: nil, email: 'invalid@example.com', password: 'password123' } }
        schema type: :object,
               properties: {
                 errors: {
                   type: :array,
                   items: { type: :string },
                   description: 'Array of error messages'
                 }
               },
               required: ['errors']

        run_test! do |response|
          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response['errors']).to include("Name can't be blank")
        end
      end
    end
  end

  # --- POST /login ---
  path '/login' do
    post 'Logs in a user and returns an authentication token' do
      tags 'Authentication'
      consumes 'application/json'

      parameter name: :credentials, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, format: 'email', description: 'User\'s email address' },
          password: { type: :string, format: 'password', description: 'User\'s password' }
        },
        required: %w[email password]
      }, description: 'User login credentials'

      response '200', 'login successful, token returned' do
        let!(:user) { User.create!(name: "Test User", email: "test@example.com", password: "correctpassword", role: :user) }
        let(:credentials) { { email: 'test@example.com', password: 'correctpassword' } }
        schema type: :object,
               properties: {
                 token: { type: :string, description: 'JWT authentication token' },
                 role: { type: :string, enum: ['user', 'admin'], description: 'Role of the authenticated user' }
               },
               required: %w[token role]

        run_test! do |response|
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response['token']).to be_present
          expect(json_response['role']).to eq('user')
        end
      end

      response '401', 'invalid credentials' do
        let!(:user) { User.create!(name: "Test User", email: "test@example.com", password: "correctpassword", role: :user) }
        let(:credentials) { { email: 'test@example.com', password: 'wrongpassword' } }
        schema type: :object,
               properties: {
                 error: { type: :string, description: 'Error message indicating invalid credentials' }
               },
               required: ['error']

        run_test! do |response|
          expect(response).to have_http_status(:unauthorized)
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq('Invalid credentials')
        end
      end
    end
  end

  # --- PATCH /users/update_role (Update User Role) ---
  path '/users/update_role' do
    patch 'Updates a user\'s role (Any Authenticated User)' do
      tags 'Authentication'
      security [Bearer: []]
      consumes 'application/json'

      parameter name: :user_role_update, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, format: :email, description: 'Email of the user whose role is to be updated' },
          role: { type: :string, enum: ['user', 'admin'], description: 'The new role for the user' }
        },
        required: %w[email role]
      }, description: 'User role update parameters'

      response '200', 'user role updated successfully' do
        let!(:admin_user) { User.create!(name: "Admin for Role Update", email: "role_admin@example.com", password: "password", role: :admin) }
        let!(:user_to_be_updated) { User.create!(name: "User To Update Role", email: "update_me@example.com", password: "password", role: :user) }
        let!(:regular_updater_user) { User.create!(name: "Regular Updater", email: "updater@example.com", password: "password", role: :user) }

        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: regular_updater_user.id)}" }
        let(:user_role_update) do
          {
            email: user_to_be_updated.email,
            role: 'admin'
          }
        end

        schema type: :object,
               properties: {
                 message: { type: :string, example: "User role updated successfully" },
                 user: {
                   type: :object,
                   properties: {
                     id: { type: :integer },
                     email: { type: :string, format: :email },
                     role: { type: :string, enum: ['user', 'admin'] }
                   },
                   required: %w[id email role]
                 }
               },
               required: %w[message user]

        run_test! do |response|
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response['user']['email']).to eq(user_to_be_updated.email)
          expect(json_response['user']['role']).to eq('admin')
          expect(user_to_be_updated.reload.role).to eq('admin')
        end
      end

      response '401', 'unauthorized (no token)' do
        let(:Authorization) { "" } # No authorization token
        let(:user_role_update) { { email: "any@example.com", role: "user" } }

        schema type: :object,
               properties: {
                 errors: { type: :string, example: "Unauthorized" }
               },
               required: ['errors']
        run_test!
      end

      response '404', 'user not found' do
        let!(:admin_user) { User.create!(name: "Admin for 404", email: "admin_404@example.com", password: "password", role: :admin) }
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: admin_user.id)}" }
        let(:user_role_update) { { email: "nonexistent@example.com", role: "user" } }

        schema type: :object,
               properties: {
                 errors: { type: :string, example: "User with email 'nonexistent@example.com' not found" }
               },
               required: ['errors']
        run_test!
      end

      response '422', 'invalid role specified' do
        let!(:admin_user) { User.create!(name: "Admin for 422", email: "admin_422@example.com", password: "password", role: :admin) }
        let!(:user_for_invalid_role) { User.create!(name: "User for Invalid Role", email: "invalid_role_user@example.com", password: "password", role: :user) }

        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: admin_user.id)}" }
        let(:user_role_update) { { email: user_for_invalid_role.email, role: 'super_admin' } }

        schema type: :object,
               properties: {
                 errors: { type: :string, example: "Invalid role specified" }
               },
               required: ['errors']
        run_test!
      end
    end
  end



  describe 'POST /register (detailed validation)' do
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
        expect(json_response['role']).to eq('user')
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

  describe 'POST /login (detailed validation)' do
    let!(:user) { User.create!(name: "Test User", email: "test@example.com", password: "correctpassword", role: :user) }
    let!(:admin_user) { User.create!(name: "Admin User", email: "admin@example.com", password: "adminpassword", role: :admin) }

    context 'with valid credentials' do
      it 'returns a token for a regular user' do
        post '/login', params: { email: 'test@example.com', password: 'correctpassword' }
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['token']).to be_present
        expect(json_response['role']).to eq('user')

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