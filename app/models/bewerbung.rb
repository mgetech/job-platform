class Bewerbung < ApplicationRecord
  self.table_name = 'bewerbungen'
  belongs_to :user
  belongs_to :job

  validates :user_id, uniqueness: { scope: :job_id, message: "has already applied to this job" }
end