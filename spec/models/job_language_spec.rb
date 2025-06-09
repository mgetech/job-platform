require 'rails_helper'

RSpec.describe JobLanguage, type: :model do
  let!(:job) { Job.create!(title: "Test Job", hourly_salary: 10.00, language_ids: [Language.create!(name: "Test").id], shifts_attributes: [{ start_time: 1.day.from_now.at_noon, end_time: 1.day.from_now.at_noon + 1.hour }]) }
  let!(:language) { Language.create!(name: "Another Test Language") }

  # --- Associations ---
  describe 'associations' do
    it { should belong_to(:job) }
    it { should belong_to(:language) }

    it 'is invalid without a job' do
      job_language = JobLanguage.new(language: language)
      expect(job_language).not_to be_valid
      expect(job_language.errors[:job]).to include("must exist")
    end

    it 'is invalid without a language' do
      job_language = JobLanguage.new(job: job)
      expect(job_language).not_to be_valid
      expect(job_language.errors[:language]).to include("must exist")
    end
  end
end
