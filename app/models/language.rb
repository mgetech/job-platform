class Language < ApplicationRecord
  has_many :job_languages
  has_many :jobs, through: :job_languages

  validates :name, presence: true, uniqueness: true
end