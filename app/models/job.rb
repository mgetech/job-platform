class Job < ApplicationRecord
  has_many :job_languages, dependent: :destroy
  has_many :languages, through: :job_languages
  has_many :shifts, dependent: :destroy

  accepts_nested_attributes_for :shifts, allow_destroy: true
  accepts_nested_attributes_for :languages, allow_destroy: true

  validates :title, presence: true
  validates :hourly_salary, numericality: { greater_than: 0 }
  validate :must_have_languages
  validate :must_have_valid_shifts

  def total_earnings
    total_hours = shifts.sum { |s| ((s.end_time - s.start_time) / 1.hour).round(2) }
    (total_hours * hourly_salary).round(2)
  end

  private

  def must_have_languages
    errors.add(:languages, "must have at least one language") if languages.empty?
  end

  def must_have_valid_shifts
    if shifts.empty?
      errors.add(:shifts, "must have at least one shift")
    elsif shifts.size > 7
      errors.add(:shifts, "cannot have more than 7 shifts")
    end
  end
end
