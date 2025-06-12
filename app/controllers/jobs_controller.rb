class JobsController < ApplicationController
  skip_before_action :authenticate_request!, only: [:index]
  before_action :authorize_admin!, only: [:create]

  def index
    # Delegate complex querying to JobsQuery object
    jobs = JobsQuery.new(params).call
    # Delegate serialization to JobSerializer
    render json: jobs.map { |job| JobSerializer.new(job).as_json }, status: :ok
  end

  def create
    Rails.logger.info "Received params: #{params.inspect}"
    Rails.logger.info "Permitted job_params: #{job_params.inspect}"
    job = Job.new(job_params)
    Rails.logger.info "Job languages before save: #{job.languages.inspect}"

    if job.save
      render json: JobSerializer.new(job).as_json, status: :created
    else
      render json: { errors: job.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def job_params
    params.require(:job).permit(
      :title,
      :hourly_salary,
      language_ids: [], # Use language_ids for existing languages
      shifts_attributes: [:id, :start_time, :end_time, :_destroy] # Added :id and :_destroy for nested attributes updates/deletions
    )
  end

end