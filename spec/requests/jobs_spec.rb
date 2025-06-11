# spec/requests/jobs_spec.rb
require 'swagger_helper'

RSpec.describe 'Jobs API', type: :request do
  # --- Authentication Setup ---
  let!(:admin_user) { User.create!(name: "Admin User", email: "admin_test@example.com", password: "password", role: :admin) }
  let!(:regular_user) { User.create!(name: "Regular User", email: "regular_test@example.com", password: "password", role: :user) }

  let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: admin_user.id)}" }
  let(:admin_token) { "Bearer #{JsonWebToken.encode(user_id: admin_user.id)}" }
  let(:regular_user_token) { "Bearer #{JsonWebToken.encode(user_id: regular_user.id)}" }
  let(:no_token) { "" }

  let(:admin_headers) { { 'Authorization' => admin_token } }
  let(:regular_user_headers) { { 'Authorization' => regular_user_token } }
  let(:no_auth_headers) { {} }


  # --- Language Setup ---
  let!(:english) { Language.create!(name: "English") }
  let!(:german) { Language.create!(name: "German") }
  let!(:spanish) { Language.create!(name: "Spanish") }

  def create_basic_job(title:, hourly_salary:, languages:, shifts_attributes:)
    Job.create!(
      title: title,
      hourly_salary: hourly_salary,
      languages: languages,
      shifts_attributes: shifts_attributes
    )
  end

  # --- POST /jobs (Create Job) ---
  path '/jobs' do
    post 'Creates a new job posting' do
      tags 'Jobs'
      security [Bearer: []]
      consumes 'application/json' # Ensure this is present and correct

      parameter name: :job, in: :body, schema: {
        type: :object,
        properties: {
          title: { type: :string, description: 'Title of the job posting' },
          hourly_salary: { type: :number, format: :float, description: 'Hourly salary for the job' },
          language_ids: {
            type: :array,
            items: { type: :integer },
            description: 'IDs of languages required for the job (at least one)'
          },
          shifts_attributes: {
            type: :array,
            items: {
              type: :object,
              properties: {
                start_time: { type: :string, format: 'date-time', description: 'Start time of the shift' },
                end_time: { type: :string, format: 'date-time', description: 'End time of the shift' }
              },
              required: %w[start_time end_time]
            },
            description: 'Array of shift attributes (at least one, max 7)'
          }
        },
        required: %w[title hourly_salary language_ids shifts_attributes]
      }, description: 'Job creation parameters',
                # ENSURE THIS 'example' BLOCK IS AT THE SAME LEVEL AS 'name', 'in', 'schema', 'description'
                example: {
                  job: { # This 'job' key must be here to match your controller's params.require(:job)
                         title: "Example Job Title",
                         hourly_salary: 30.0,
                         language_ids: [1], # IMPORTANT: Use a valid language ID from your DEVELOPMENT DB (e.g., check `Language.all.pluck(:id, :name)` in `rails c`)
                         shifts_attributes: [
                           { start_time: (1.day.from_now + 9.hours).iso8601, end_time: (1.day.from_now + 17.hours).iso8601 }
                         ]
                  }
                }

      response '201', 'job created successfully' do
        # MODIFIED: Provide a robust example for `let(:job)` that will be sent by Rswag
        let(:job) do
          {
            job: {title: "Example Job for Docs",
                  hourly_salary: 35.0,
                  language_ids: [english.id],
                  shifts_attributes: [
                    { start_time: 1.day.from_now.iso8601, end_time: (1.day.from_now + 8.hours).iso8601 }
                  ]
                }
          }
        end
        let(:Authorization) { admin_token }

        schema type: :object,
               properties: {
                 id: { type: :integer, description: 'ID of the created job' },
                 title: { type: :string, description: 'Title of the job' },
                 hourly_salary: { type: :string, description: 'Hourly salary' }, # CHANGED TO STRING
                 spoken_languages: { type: :array, items: { type: :string }, description: 'Names of languages required' },
                 shift_hours: { type: :array, items: { type: :number, format: :float }, description: 'Duration of each shift in hours' },
                 total_earnings: { type: :string, description: 'Total potential earnings for all shifts combined' } # CHANGED TO STRING
               },
               required: %w[id title hourly_salary spoken_languages shift_hours total_earnings]

        run_test! do |response|
          expect(response).to have_http_status(:created)
          json_response = JSON.parse(response.body)
          expect(json_response['title']).to be_present # Use general assertion as actual value depends on let(:job)
          expect(json_response['hourly_salary']).to be_present
        end
      end

      response '422', 'invalid parameters' do
        let(:job) { { title: nil, hourly_salary: -10 } }
        let(:Authorization) { admin_token }

        schema type: :object,
               properties: {
                 errors: {
                   type: :array,
                   items: { type: :string, example: "Title can't be blank" },
                   description: 'Array of error messages from validation'
                 }
               },
               required: ['errors']

        run_test!
      end

      response '403', 'forbidden (not admin)' do
        let(:job) { { title: "Forbidden Test", hourly_salary: 10, language_ids: [english.id], shifts_attributes: [{start_time: Time.now.iso8601, end_time: (Time.now + 1.hour).iso8601}] } } # Minimal valid params for this
        let(:Authorization) { regular_user_token }

        schema type: :object,
               properties: {
                 error: { type: :string, example: "Forbidden", description: 'Error message indicating insufficient permissions' }
               },
               required: ['error']

        run_test!
      end

      response '401', 'unauthorized (no or invalid token)' do
        let(:job) { { title: "Unauthorized Test", hourly_salary: 10, language_ids: [english.id], shifts_attributes: [{start_time: Time.now.iso8601, end_time: (Time.now + 1.hour).iso8601}] } } # Minimal valid params for this
        let(:Authorization) { no_token }

        schema type: :object,
               properties: {
                 errors: { type: :string, example: "Unauthorized", description: 'Error message indicating lack of authentication' }
               },
               required: ['errors']

        run_test!
      end
    end
  end

  # --- GET /jobs (List/Search Jobs) ---
  path '/jobs' do
    get 'Retrieves a list of job postings, with optional search' do
      tags 'Jobs'
      produces 'application/json'

      parameter name: :title, in: :query, type: :string, required: false, description: 'Search by job title (case-insensitive)'
      parameter name: :language, in: :query, type: :string, required: false, description: 'Filter by spoken language (case-insensitive)'

      response '200', 'list of jobs' do
        # Setup data for the test
        let!(:job_dev_english) { create_basic_job(title: "Web Developer", hourly_salary: 30.0, languages: [english], shifts_attributes: [{start_time: 1.day.from_now, end_time: 1.day.from_now + 8.hours}]) }
        let!(:job_qa_german) { create_basic_job(title: "QA Engineer", hourly_salary: 25.0, languages: [german], shifts_attributes: [{start_time: 2.days.from_now, end_time: 2.days.from_now + 7.hours}]) }
        let!(:job_lead_english_spanish) { create_basic_job(title: "Team Lead", hourly_salary: 50.0, languages: [english, spanish], shifts_attributes: [{start_time: 3.days.from_now, end_time: 3.days.from_now + 6.hours}]) }
        let!(:job_junior_dev) { create_basic_job(title: "Junior Developer", hourly_salary: 20.0, languages: [english], shifts_attributes: [{start_time: 4.days.from_now, end_time: 4.days.from_now + 5.hours}]) }

        let(:Authorization) { no_token } # This endpoint is public, so no token is needed for the example
        let(:title) { 'Developer' } # Example query parameter for Swagger UI
        let(:language) { 'English' } # Example query parameter for Swagger UI

        schema type: :array,
               items: {
                 type: :object,
                 properties: {
                   id: { type: :integer, description: 'ID of the job' },
                   title: { type: :string, description: 'Title of the job' },
                   hourly_salary: { type: :string, description: 'Hourly salary' }, # CHANGED TO STRING
                   spoken_languages: { type: :array, items: { type: :string }, description: 'Names of languages required' },
                   shift_hours: { type: :array, items: { type: :number, format: :float }, description: 'Duration of each shift in hours' },
                   total_earnings: { type: :string, description: 'Total potential earnings for all shifts combined' } # CHANGED TO STRING
                 },
                 required: %w[id title hourly_salary spoken_languages shift_hours total_earnings]
               }

        run_test!
      end
    end
  end

  # --- Original RSpec contexts and tests for detailed validation (MOVED INSIDE THE MAIN DESCRIBE BLOCK) ---
  describe 'POST /jobs (detailed RSpec validation)' do
    let(:valid_shift_attributes) do
      [
        { start_time: 2.days.from_now.at_noon, end_time: 2.days.from_now.at_noon + 8.hours },
        { start_time: 3.days.from_now.at_noon, end_time: 3.days.from_now.at_noon + 6.hours }
      ]
    end

    let(:valid_job_params) do
      {
        job: {
          title: "Senior Software Developer",
          hourly_salary: 45.00,
          language_ids: [english.id, german.id],
          shifts_attributes: valid_shift_attributes
        }
      }
    end

    context 'when authenticated as an admin' do
      it 'creates a new job with valid attributes, shifts, and languages' do
        expect {
          post '/jobs', params: valid_job_params, headers: admin_headers
        }.to change(Job, :count).by(1)
                                .and change(Shift, :count).by(2)
                                                          .and change(JobLanguage, :count).by(2)

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)

        expect(json_response['id']).to be_present
        expect(json_response['title']).to eq("Senior Software Developer")
        expect(json_response['hourly_salary'].to_f).to eq(45.0)
        expect(json_response['spoken_languages']).to match_array(["English", "German"])
        expect(json_response['shift_hours'].sum).to eq(14.0)
        expect(json_response['total_earnings'].to_f).to eq(630.0)

        created_job = Job.last
        expect(created_job.title).to eq("Senior Software Developer")
        expect(created_job.hourly_salary.to_f).to eq(45.0)
        expect(created_job.languages.map(&:name)).to match_array(["English", "German"])
        expect(created_job.shifts.count).to eq(2)
      end

      it 'returns unprocessable entity with invalid job parameters' do
        invalid_params = valid_job_params.deep_merge(job: { title: nil, hourly_salary: -10 })
        post '/jobs', params: invalid_params, headers: admin_headers
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include("Title can't be blank", "Hourly salary must be greater than 0")
      end

      it 'returns unprocessable entity if no languages are provided' do
        params_without_languages = valid_job_params.deep_merge(job: { language_ids: [] })
        post '/jobs', params: params_without_languages, headers: admin_headers
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include("Languages must have at least one language")
      end

      it 'returns unprocessable entity if no shifts are provided' do
        params_without_shifts = valid_job_params.deep_merge(job: { shifts_attributes: [] })
        post '/jobs', params: params_without_shifts, headers: admin_headers
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include("Shifts must have at least one shift")
      end

      it 'returns unprocessable entity if shifts are more than 7' do
        eight_shifts = Array.new(8) do |i|
          { start_time: (i + 1).days.from_now.at_noon, end_time: (i + 1).days.from_now.at_noon + 8.hours }
        end
        params_too_many_shifts = valid_job_params.deep_merge(job: { shifts_attributes: eight_shifts })
        post '/jobs', params: params_too_many_shifts, headers: admin_headers
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include("Shifts cannot have more than 7 shifts")
      end

      it 'returns unprocessable entity if a shift has end_time before start_time' do
        invalid_shift_params = valid_job_params.deep_merge(job: { shifts_attributes: [{ start_time: 2.hours.from_now, end_time: 1.hour.from_now }] })
        post '/jobs', params: invalid_shift_params, headers: admin_headers
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include("Shifts end time must be after start time")
      end
    end

    context 'when authenticated as a regular user' do
      it 'returns forbidden status' do
        post '/jobs', params: valid_job_params, headers: regular_user_headers
        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)['error']).to eq('Forbidden')
      end
    end

    context 'when unauthenticated' do
      it 'returns unauthorized status' do
        post '/jobs', params: valid_job_params, headers: no_auth_headers
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['errors']).to eq('Unauthorized')
      end
    end
  end

  describe 'GET /jobs (detailed RSpec validation)' do
    # Create some diverse job data directly for search tests
    let!(:job_dev_english) { create_basic_job(title: "Web Developer", hourly_salary: 30.0, languages: [english], shifts_attributes: [{start_time: 1.day.from_now, end_time: 1.day.from_now + 8.hours}]) }
    let!(:job_qa_german) { create_basic_job(title: "QA Engineer", hourly_salary: 25.0, languages: [german], shifts_attributes: [{start_time: 2.days.from_now, end_time: 2.days.from_now + 7.hours}]) }
    let!(:job_lead_english_spanish) { create_basic_job(title: "Team Lead", hourly_salary: 50.0, languages: [english, spanish], shifts_attributes: [{start_time: 3.days.from_now, end_time: 3.days.from_now + 6.hours}]) }
    let!(:job_junior_dev) { create_basic_job(title: "Junior Developer", hourly_salary: 20.0, languages: [english], shifts_attributes: [{start_time: 4.days.from_now, end_time: 4.days.from_now + 5.hours}]) }

    context 'without search parameters' do
      it 'returns all available jobs' do
        get '/jobs', headers: no_auth_headers # Index is public
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response.count).to eq(4)

        first_job = json_response.first
        expect(first_job).to include('id', 'title', 'hourly_salary', 'total_earnings', 'spoken_languages', 'shift_hours')
        expect(first_job['spoken_languages']).to be_an(Array)
        expect(first_job['shift_hours']).to be_an(Array)
      end
    end

    context 'with title search parameter' do
      it 'returns jobs matching the title (case-insensitive)' do
        get '/jobs', params: { title: 'developer' }, headers: no_auth_headers
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response.count).to eq(2)
        titles = json_response.map { |job| job['title'] }
        expect(titles).to match_array(["Web Developer", "Junior Developer"])
      end

      it 'returns an empty array if no title matches' do
        get '/jobs', params: { title: 'NonExistent' }, headers: no_auth_headers
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response).to be_empty
      end
    end

    context 'with language search parameter' do
      it 'returns jobs matching the language (case-insensitive)' do
        get '/jobs', params: { language: 'german' }, headers: no_auth_headers
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response.count).to eq(1)
        expect(json_response.first['title']).to eq("QA Engineer")
      end

      it 'returns jobs matching multiple languages' do
        get '/jobs', params: { language: 'english' }, headers: no_auth_headers
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response.count).to eq(3)
        titles = json_response.map { |job| job['title'] }
        expect(titles).to match_array(["Web Developer", "Team Lead", "Junior Developer"])
      end

      it 'returns an empty array if no language matches' do
        get '/jobs', params: { language: 'Japanese' }, headers: no_auth_headers
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response).to be_empty
      end
    end

    context 'with both title and language search parameters' do
      it 'returns jobs matching both criteria' do
        get '/jobs', params: { title: 'developer', language: 'english' }, headers: no_auth_headers
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response.count).to eq(2)
        titles = json_response.map { |job| job['title'] }
        expect(titles).to match_array(["Web Developer", "Junior Developer"])
      end

      it 'returns an empty array if no job matches both criteria' do
        get '/jobs', params: { title: 'Lead', language: 'german' }, headers: no_auth_headers
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response).to be_empty
      end
    end
  end
end