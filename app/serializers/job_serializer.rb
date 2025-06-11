class JobSerializer
  def initialize(job)
    @job = job
  end

  def as_json(options = {})
    {
      id: @job.id,
      title: @job.title,
      hourly_salary: @job.hourly_salary,
      total_earnings: @job.total_earnings,
      spoken_languages: @job.languages.map(&:name),
      shift_hours: @job.shifts.map { |s| s.duration_hours }
    }
  end
end