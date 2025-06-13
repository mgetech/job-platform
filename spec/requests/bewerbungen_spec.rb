require 'swagger_helper'

RSpec.describe 'Bewerbungen API', type: :request do
  # --- Authentication Setup ---
  let!(:admin_user) { User.create!(name: "Admin User", email: "admin@example.com", password: "password", role: :admin) }
  let!(:regular_user_1) { User.create!(name: "Regular User 1", email: "user1@example.com", password: "password", role: :user) }
  let!(:regular_user_2) { User.create!(name: "Regular User 2", email: "user2@example.com", password: "password", role: :user) }

  let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: regular_user_1.id)}" }
  let(:admin_token) { "Bearer #{JsonWebToken.encode(user_id: admin_user.id)}" }
  let(:regular_user_1_token) { "Bearer #{JsonWebToken.encode(user_id: regular_user_1.id)}" }
  let(:regular_user_2_token) { "Bearer #{JsonWebToken.encode(user_id: regular_user_2.id)}" }
  let(:invalid_token) { "Bearer invalid.token.string" }
  let(:no_token) { "" }

  let(:admin_headers) { { 'Authorization' => admin_token } }
  let(:regular_user_1_headers) { { 'Authorization' => regular_user_1_token } }
  let(:regular_user_2_headers) { { 'Authorization' => regular_user_2_token } }
  let(:no_auth_headers) { {} }


  # --- Job and Language Setup ---
  let!(:language_english) { Language.create!(name: "English") }
  let!(:job_a) do
    Job.create!(
      title: "Job A",
      hourly_salary: 25.0,
      languages: [language_english],
      shifts_attributes: [{ start_time: 1.day.from_now, end_time: 1.day.from_now + 8.hours }]
    )
  end
  let!(:job_b) do
    Job.create!(
      title: "Job B",
      hourly_salary: 30.0,
      languages: [language_english],
      shifts_attributes: [{ start_time: 2.days.from_now, end_time: 2.days.from_now + 7.hours }]
    )
  end
  let!(:job_c) do
    Job.create!(
      title: "Job C",
      hourly_salary: 20.0,
      languages: [language_english],
      shifts_attributes: [{ start_time: 3.days.from_now, end_time: 3.days.from_now + 6.hours }]
    )
  end


  # --- POST /jobs/:job_id/bewerbungen (Create Application) ---
  path '/jobs/{job_id}/bewerbungen' do
    post 'Creates a new job application for the authenticated user' do
      tags 'Applications'
      security [Bearer: []]

      parameter name: :job_id, in: :path, type: :integer, required: true, description: 'ID of the Job to apply for'

      response '201', 'application submitted successfully' do
        let(:job_id) { job_a.id }
        let(:Authorization) { regular_user_1_token }

        schema type: :object,
               properties: {
                 message: { type: :string, example: "Application submitted successfully" },
                 bewerbung: {
                   type: :object,
                   properties: {
                     id: { type: :integer, description: 'ID of the created application' },
                     job_id: { type: :integer, description: 'ID of the job the user applied for' },
                     job_title: { type: :string, description: 'Title of the job applied for' },
                     applied_at: { type: :string, format: 'date-time', description: 'Timestamp when the application was created' }
                   },
                   required: %w[id job_id job_title applied_at]
                 }
               },
               required: %w[message bewerbung]

        run_test! do |response|
          expect(response).to have_http_status(:created)
          json_response = JSON.parse(response.body)
          expect(json_response['message']).to eq("Application submitted successfully")
          expect(json_response['bewerbung']['job_id']).to eq(job_a.id)
          expect(json_response['bewerbung']['job_title']).to eq(job_a.title)
        end
      end

      response '422', 'unprocessable entity (e.g., user already applied)' do
        let(:job_id) { job_a.id }
        let(:Authorization) { regular_user_1_token }
        before { Bewerbung.create!(user: regular_user_1, job: job_a) }

        schema type: :object,
               properties: {
                 errors: {
                   type: :array,
                   items: { type: :string, example: "User has already applied to this job" },
                   description: 'Array of error messages from validation'
                 }
               },
               required: ['errors']

        run_test! do |response|
          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response['errors']).to include("User has already applied to this job")
        end
      end

      response '404', 'not found (job does not exist)' do
        let(:job_id) { 99999 }
        let(:Authorization) { regular_user_1_token }

        schema type: :object,
               properties: {
                 errors: { type: :string, example: "Record not found", description: 'Error message indicating resource not found' }
               },
               required: ['errors']

        run_test! do |response|
          expect(response).to have_http_status(:not_found)
          json_response = JSON.parse(response.body)
          expect(json_response['errors']).to eq("Record not found")
        end
      end

      response '401', 'unauthorized (no or invalid token)' do
        let(:job_id) { job_c.id }
        let(:Authorization) { no_token }

        schema type: :object,
               properties: {
                 errors: { type: :string, example: "Unauthorized", description: 'Error message indicating lack of authentication' }
               },
               required: ['errors']

        run_test! do |response|
          expect(response).to have_http_status(:unauthorized)
          expect(JSON.parse(response.body)['errors']).to eq('Unauthorized')
        end
      end
    end
  end

  # --- GET /bewerbungen (List User's Applications) ---
  path '/bewerbungen' do
    get 'Retrieves all job applications for the authenticated user' do
      tags 'Applications'
      security [Bearer: []]
      produces 'application/json'

      response '200', 'list of user applications' do
        let!(:app_user1_job_a) { Bewerbung.create!(user: regular_user_1, job: job_a, created_at: 2.days.ago) }
        let!(:app_user1_job_b) { Bewerbung.create!(user: regular_user_1, job: job_b, created_at: 1.day.ago) }
        let(:Authorization) { regular_user_1_token }

        schema type: :array,
               items: {
                 type: :object,
                 properties: {
                   id: { type: :integer, description: 'ID of the application' },
                   job_id: { type: :integer, description: 'ID of the applied job' },
                   job_title: { type: :string, description: 'Title of the job applied for' },
                   applied_at: { type: :string, format: 'date-time', description: 'Timestamp when the application was created' }
                 },
                 required: %w[id job_id job_title applied_at]
               }

        run_test! do |response|
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response.count).to eq(2)
          expect(json_response.map { |app| app['job_title'] }).to match_array([job_a.title, job_b.title])
        end
      end

      response '401', 'unauthorized (no or invalid token)' do
        let(:Authorization) { no_token }

        schema type: :object,
               properties: {
                 errors: { type: :string, example: "Unauthorized", description: 'Error message indicating lack of authentication' }
               },
               required: ['errors']

        run_test! do |response|
          expect(response).to have_http_status(:unauthorized)
          expect(JSON.parse(response.body)['errors']).to eq('Unauthorized')
        end
      end
    end
  end

  # --- Original RSpec contexts and tests for detailed validation ---

  describe 'POST /jobs/:job_id/bewerbungen (detailed RSpec validation)' do
    context 'when authenticated as a regular user' do
      it 'creates a new job application successfully' do
        expect {
          post "/jobs/#{job_a.id}/bewerbungen", headers: regular_user_1_headers
        }.to change(Bewerbung, :count).by(1)

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq("Application submitted successfully")
        expect(json_response['bewerbung']['job_id']).to eq(job_a.id)
        expect(json_response['bewerbung']['job_title']).to eq(job_a.title)

        created_bewerbung = Bewerbung.last
        expect(created_bewerbung.user).to eq(regular_user_1)
        expect(created_bewerbung.job).to eq(job_a)
      end

      it 'returns unprocessable entity if the user already applied to the job' do
        Bewerbung.create!(user: regular_user_1, job: job_a)
        expect {
          post "/jobs/#{job_a.id}/bewerbungen", headers: regular_user_1_headers
        }.not_to change(Bewerbung, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include("User has already applied to this job")
      end

      it 'returns not found status if the job does not exist' do
        post "/jobs/99999/bewerbungen", headers: regular_user_1_headers
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to eq("Record not found")
      end
    end

    context 'when authenticated as an admin user' do
      it 'creates a new job application successfully (admins can apply too)' do
        expect {
          post "/jobs/#{job_b.id}/bewerbungen", headers: admin_headers
        }.to change(Bewerbung, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(Bewerbung.last.user).to eq(admin_user)
      end
    end

    context 'when unauthenticated' do
      it 'returns unauthorized status' do
        expect {
          post "/jobs/#{job_c.id}/bewerbungen", headers: no_auth_headers
        }.not_to change(Bewerbung, :count)

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['errors']).to eq('Unauthorized')
      end
    end
  end

  describe 'GET /bewerbungen (detailed RSpec validation)' do
    let!(:app_user1_job_a) { Bewerbung.create!(user: regular_user_1, job: job_a, created_at: 2.days.ago) }
    let!(:app_user1_job_b) { Bewerbung.create!(user: regular_user_1, job: job_b, created_at: 1.day.ago) }
    let!(:app_user2_job_c) { Bewerbung.create!(user: regular_user_2, job: job_c) }

    context 'when authenticated as regular_user_1' do
      it 'returns a list of their own job applications' do
        get '/bewerbungen', headers: regular_user_1_headers
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        expect(json_response.count).to eq(2)
        expect(json_response.map { |app| app['job_title'] }).to match_array([job_a.title, job_b.title])
        expect(json_response.map { |app| app['job_id'] }).to match_array([job_a.id, job_b.id])

        first_app = json_response.find { |app| app['job_id'] == job_a.id }
        expect(first_app).to include('id', 'job_id', 'job_title', 'applied_at')
        expect(first_app['id']).to eq(app_user1_job_a.id)
        expect(first_app['applied_at']).to be_present
      end

      it 'returns an empty array if the user has no applications' do
        no_apps_user = User.create!(name: "No Apps User", email: "noapps@example.com", password: "password", role: :user)
        no_apps_headers = { 'Authorization' => "Bearer #{JsonWebToken.encode(user_id: no_apps_user.id)}" }

        get '/bewerbungen', headers: no_apps_headers
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response).to be_empty
      end
    end

    context 'when unauthenticated' do
      it 'returns unauthorized status' do
        get '/bewerbungen', headers: no_auth_headers
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['errors']).to eq('Unauthorized')
      end
    end
  end
end