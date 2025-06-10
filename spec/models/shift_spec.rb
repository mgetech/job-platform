require 'rails_helper'

RSpec.describe Shift, type: :model do
  let!(:job) { Job.create!(title: "Test Job", hourly_salary: 10.00, language_ids: [Language.create!(name: "Test").id], shifts_attributes: [{ start_time: 1.day.from_now.at_noon, end_time: 1.day.from_now.at_noon + 1.hour }]) }

  # --- Associations ---
  describe 'associations' do
    it { should belong_to(:job) }
  end

  # --- Validations ---
  describe 'validations' do
    it 'is valid with valid attributes' do
      shift = Shift.new(job: job, start_time: 1.hour.from_now, end_time: 2.hours.from_now)
      expect(shift).to be_valid
    end

    it 'is invalid without a start_time' do
      shift = Shift.new(job: job, start_time: nil, end_time: 2.hours.from_now)
      expect(shift).not_to be_valid
      expect(shift.errors[:start_time]).to include("can't be blank")
    end

    it 'is invalid without an end_time' do
      shift = Shift.new(job: job, start_time: 1.hour.from_now, end_time: nil)
      expect(shift).not_to be_valid
      expect(shift.errors[:end_time]).to include("can't be blank")
    end

    describe 'custom validation: end_after_start' do
      it 'is invalid if end_time is before start_time' do
        shift = Shift.new(job: job, start_time: 2.hours.from_now, end_time: 1.hour.from_now)
        expect(shift).not_to be_valid
        expect(shift.errors[:end_time]).to include("must be after start time")
      end

      it 'is invalid if end_time is the same as start_time' do
        time = 2.hours.from_now
        shift = Shift.new(job: job, start_time: time, end_time: time)
        expect(shift).not_to be_valid
        expect(shift.errors[:end_time]).to include("must be after start time")
      end

      it 'is valid if end_time is after start_time' do
        shift = Shift.new(job: job, start_time: 1.hour.from_now, end_time: 2.hours.from_now)
        expect(shift).to be_valid
      end
    end
  end

  # --- Instance Methods ---
  describe '#duration_hours' do
    it 'calculates duration in hours correctly' do
      start_time = DateTime.parse('2025-01-01 09:00:00')
      end_time = DateTime.parse('2025-01-01 17:30:00') # 8.5 hours
      shift = Shift.new(job: job, start_time: start_time, end_time: end_time)
      expect(shift.duration_hours).to eq(8.50)
    end

    it 'handles fractional hours and rounds to two decimal places' do
      start_time = DateTime.parse('2025-01-01 09:00:00')
      end_time = DateTime.parse('2025-01-01 09:15:00') # 0.25 hours
      shift = Shift.new(job: job, start_time: start_time, end_time: end_time)
      expect(shift.duration_hours).to eq(0.25)
    end
  end
end
