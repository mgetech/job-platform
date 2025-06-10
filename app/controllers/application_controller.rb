class ApplicationController < ActionController::API
  include JsonWebToken

  # Add this block to handle ActiveRecord::RecordNotFound errors globally
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  before_action :authenticate_request!

  attr_reader :current_user

  private

  def authenticate_request!
    header = request.headers['Authorization']
    header = header.split(' ').last if header
    unless header
      render json: { errors: 'Unauthorized', details: 'No authentication token provided.' }, status: :unauthorized and return
    end

    def render_not_found(exception)
      render json: { errors: "Record not found" }, status: :not_found
    end

    begin
      @decoded = JsonWebToken.decode(header)
      @current_user = User.find(@decoded[:user_id])
    rescue ActiveRecord::RecordNotFound => e
      render json: { errors: 'Unauthorized', details: e.message }, status: :unauthorized and return
    rescue JWT::DecodeError => e
      render json: { errors: 'Unauthorized', details: e.message }, status: :unauthorized and return
    end
  end

  def authorize_admin!
    unless @current_user&.admin?
      render json: { error: 'Forbidden' }, status: :forbidden and return
    end
  end
end