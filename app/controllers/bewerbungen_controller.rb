class BewerbungenController < ApplicationController
  before_action :authenticate_request!

  def create
    job = Job.find(params[:job_id])
    bewerbung = current_user.bewerbungen.build(job: job)

    if bewerbung.save
      render json: { message: "Application submitted successfully", bewerbung: BewerbungSerializer.new(bewerbung).as_json }, status: :created
    else
      render json: { errors: bewerbung.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def index
    bewerbungen = current_user.bewerbungen.includes(:job)
    render json: bewerbungen.map { |b| BewerbungSerializer.new(b).as_json }, status: :ok
  end
end