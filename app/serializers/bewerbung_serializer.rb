class BewerbungSerializer
  def initialize(bewerbung)
    @bewerbung = bewerbung
  end

  def as_json(options = {})
    {
      id: @bewerbung.id,
      job_id: @bewerbung.job.id,
      job_title: @bewerbung.job.title,
      applied_at: @bewerbung.created_at
    }
  end
end