class Shift < ApplicationRecord
  belongs_to :job

  validates :start_time, presence: true
  validates :end_time, presence: true
  validate :end_after_start

  def duration_hours
    ((end_time - start_time) / 1.hour).round(2)
  end

  private

  def end_after_start
    return if end_time.nil? || start_time.nil? # Handle nil dates gracefully
    errors.add(:end_time, "must be after start time") unless end_time > start_time
  end
end