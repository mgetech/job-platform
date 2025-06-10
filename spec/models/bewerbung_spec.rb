require 'rails_helper'

RSpec.describe Bewerbung, type: :model do
  # Use `let!` to ensure these records are created before each example
  # and cleaned by DatabaseCleaner
  let!(:user) { User.create!(name: "Applicant User", email: "applicant@example.com", password: "password", role: :user) }
  let!(:admin_user) { User.create!(name: "Admin User", email: "admin@example.com", password: "password", role: :admin) }
  let!(:language) { Language.create!(name: "English") } # Needed for job creation
  let!(:job) do
    Job.create!(
      title: "Test Job for Bewerbung",
      hourly_salary: 20.0,
      languages: [language],
      shifts_attributes: [{ start_time: 1.day.from_now, end_time: 1.day.from_now + 8.hours }]
    )
  end

  # --- Associations ---
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:job) }
  end

  # --- Validations ---
  describe 'validations' do
    it 'is valid with valid attributes' do
      bewerbung = Bewerbung.new(user: user, job: job)
      expect(bewerbung).to be_valid
    end

    it 'is invalid without a user' do
      bewerbung = Bewerbung.new(user: nil, job: job)
      expect(bewerbung).not_to be_valid
      expect(bewerbung.errors[:user]).to include("must exist")
    end

    it 'is invalid without a job' do
      bewerbung = Bewerbung.new(user: user, job: nil)
      expect(bewerbung).not_to be_valid
      expect(bewerbung.errors[:job]).to include("must exist")
    end

    it 'is invalid if a user applies to the same job twice' do
      Bewerbung.create!(user: user, job: job) # First application
      duplicate_bewerbung = Bewerbung.new(user: user, job: job) # Second application
      expect(duplicate_bewerbung).not_to be_valid
      expect(duplicate_bewerbung.errors[:user_id]).to include("has already applied to this job")
    end
  end
end