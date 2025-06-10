require 'rails_helper'

RSpec.describe 'Jobs API', type: :request do
  # --- Authentication Setup ---
  # These users and tokens will be cleaned by DatabaseCleaner after each test.
  let!(:admin_user) { User.create!(name: "Admin User", username: "admin_test", password: "password", role: :admin) }
  let!(:regular_user) { User.create!(name: "Regular User", username: "regular_test", password: "password", role: :user) }
  let(:admin_headers) { { 'Authorization' => "Bearer #{JsonWebToken.encode(user_id: admin_user.id)}" } }
  let(:regular_user_headers) { { 'Authorization' => "Bearer #{JsonWebToken.encode(user_id: regular_user.id)}" } }
  let(:no_auth_headers) { {} } # For unauthenticated requests

  # --- Language Setup ---
  # These will be recreated and cleaned by DatabaseCleaner for each test.
  let!(:english) { Language.create!(name: "English") }
  let!(:german) { Language.create!(name: "German") }
  let!(:spanish) { Language.create!(name: "Spanish") }

  # A helper for creating a basic valid job for testing purposes
  def create_basic_job(title:, hourly_salary:, languages:, shifts_attributes:)
    Job.create!(
      title: title,
      hourly_salary: hourly_salary,
      languages: languages,
      shifts_attributes: shifts_attributes
    )
  end

  # --- POST /jobs (Create Job) ---
  describe 'POST /jobs' do
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
                                .and change(Shift, :count).by(2) # 2 shifts created
                                                          .and change(JobLanguage, :count).by(2) # 2 languages linked

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)

        expect(json_response['id']).to be_present
        expect(json_response['title']).to eq("Senior Software Developer")
        expect(json_response['hourly_salary'].to_f).to eq(45.0)
        expect(json_response['spoken_languages']).to match_array(["English", "German"])
        expect(json_response['shift_hours'].sum).to eq(14.0) # 8 + 6 hours
        expect(json_response['total_earnings'].to_f).to eq(630.0) # 45.0 * 14.0

        # Verify job data in the database
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
        # Note: The error message will typically come from the Shift model's validation
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

  # --- GET /jobs (List/Search Jobs) ---
  describe 'GET /jobs' do
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
        expect(json_response.count).to eq(4) # All 4 jobs created above

        # Check structure of one job
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
        expect(json_response.count).to eq(3) # Web Dev, Team Lead, Junior Dev
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
