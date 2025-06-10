require 'rails_helper'

RSpec.describe Job, type: :model do
  let!(:language_english) { Language.create!(name: "English") }
  let!(:language_german) { Language.create!(name: "German") }

  # A valid job factory or build helper for common setup
  def build_valid_job(attributes = {})
    Job.new({
              title: "Software Engineer",
              hourly_salary: 25.00,
              language_ids: [language_english.id],
              shifts_attributes: [
                { start_time: 1.day.from_now.at_noon, end_time: 1.day.from_now.at_noon + 8.hours }
              ]
            }.merge(attributes))
  end

  # --- Associations ---
  describe 'associations' do
    it { should have_many(:job_languages).dependent(:destroy) }
    it { should have_many(:languages).through(:job_languages) }
    it { should have_many(:shifts).dependent(:destroy) }
  end

  # --- Validations ---
  describe 'validations' do
    it 'is valid with valid attributes' do
      job = build_valid_job
      expect(job).to be_valid
    end

    it 'is invalid without a title' do
      job = build_valid_job(title: nil)
      expect(job).not_to be_valid
      expect(job.errors[:title]).to include("can't be blank")
    end

    it 'is invalid with a non-positive hourly_salary' do
      job = build_valid_job(hourly_salary: 0)
      expect(job).not_to be_valid
      expect(job.errors[:hourly_salary]).to include("must be greater than 0")

      job = build_valid_job(hourly_salary: -5)
      expect(job).not_to be_valid
      expect(job.errors[:hourly_salary]).to include("must be greater than 0")
    end

    describe 'custom validation: must_have_languages' do
      it 'is invalid without any languages' do
        job = build_valid_job(language_ids: [])
        expect(job).not_to be_valid
        expect(job.errors[:languages]).to include("must have at least one language")
      end

      it 'is valid with at least one language' do
        job = build_valid_job(language_ids: [language_english.id])
        expect(job).to be_valid
      end
    end

    describe 'custom validation: must_have_valid_shifts' do
      it 'is invalid without any shifts' do
        job = build_valid_job(shifts_attributes: [])
        expect(job).not_to be_valid
        expect(job.errors[:shifts]).to include("must have at least one shift")
      end

      it 'is invalid with more than 7 shifts' do
        # Create 8 shifts
        eight_shifts = Array.new(8) do |i|
          { start_time: (i + 1).days.from_now.at_noon, end_time: (i + 1).days.from_now.at_noon + 8.hours }
        end
        job = build_valid_job(shifts_attributes: eight_shifts)
        expect(job).not_to be_valid
        expect(job.errors[:shifts]).to include("cannot have more than 7 shifts")
      end

      it 'is valid with 1 to 7 shifts' do
        # Test with 1 shift
        job = build_valid_job(shifts_attributes: [
          { start_time: 1.day.from_now.at_noon, end_time: 1.day.from_now.at_noon + 8.hours }
        ])
        expect(job).to be_valid

        # Test with 7 shifts
        seven_shifts = Array.new(7) do |i|
          { start_time: (i + 1).days.from_now.at_noon, end_time: (i + 1).days.from_now.at_noon + 8.hours }
        end
        job = build_valid_job(shifts_attributes: seven_shifts)
        expect(job).to be_valid
      end
    end
  end

  # --- Instance Methods ---
  describe '#total_earnings' do
    it 'calculates total earnings correctly for one shift' do
      job = build_valid_job(hourly_salary: 20.00, shifts_attributes: [
        { start_time: 1.day.from_now.at_noon, end_time: 1.day.from_now.at_noon + 4.hours } # 4 hours
      ])
      job.save! # Save to ensure shifts are created and associated
      expect(job.total_earnings).to eq(80.00) # 20 * 4
    end

    it 'calculates total earnings correctly for multiple shifts' do
      job = build_valid_job(hourly_salary: 15.00, shifts_attributes: [
        { start_time: 1.day.from_now.at_noon, end_time: 1.day.from_now.at_noon + 4.hours }, # 4 hours
        { start_time: 2.days.from_now.at_noon, end_time: 2.days.from_now.at_noon + 6.hours }  # 6 hours
      ])
      job.save!
      expect(job.total_earnings).to eq(150.00) # 15 * (4 + 6) = 15 * 10
    end

    it 'handles fractional hours and rounds to two decimal places' do
      job = build_valid_job(hourly_salary: 10.50, shifts_attributes: [
        { start_time: 1.day.from_now.at_noon, end_time: 1.day.from_now.at_noon + 1.hour + 30.minutes } # 1.5 hours
      ])
      job.save!
      expect(job.total_earnings).to eq(15.75) # 10.50 * 1.5
    end

    it 'returns 0 if there are no shifts' do
      job = build_valid_job(hourly_salary: 20.00, shifts_attributes: [])
      job.save(validate: false) # Bypass shift validation for this specific test
      expect(job.total_earnings).to eq(0.00)
    end
  end

  # --- accepts_nested_attributes_for behavior ---
  describe 'accepts_nested_attributes_for' do
    it 'creates associated languages through language_ids' do
      job = Job.create!(
        title: "Test Job",
        hourly_salary: 10.00,
        language_ids: [language_english.id, language_german.id],
        shifts_attributes: [
          { start_time: 1.day.from_now.at_noon, end_time: 1.day.from_now.at_noon + 4.hours }
        ]
      )
      expect(job.languages.count).to eq(2)
      expect(job.languages).to include(language_english, language_german)
    end

    it 'creates associated shifts through shifts_attributes' do
      start_time1 = 1.day.from_now.at_noon
      end_time1 = start_time1 + 8.hours
      start_time2 = 2.days.from_now.at_noon
      end_time2 = start_time2 + 6.hours

      job = Job.create!(
        title: "Another Job",
        hourly_salary: 30.00,
        language_ids: [language_english.id],
        shifts_attributes: [
          { start_time: start_time1, end_time: end_time1 },
          { start_time: start_time2, end_time: end_time2 }
        ]
      )
      expect(job.shifts.count).to eq(2)
      expect(job.shifts.first.start_time).to be_within(1.second).of(start_time1)
      expect(job.shifts.last.end_time).to be_within(1.second).of(end_time2)
    end
  end
end
