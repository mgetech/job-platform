class ApplicationController < ActionController::API
  include JsonWebToken

  before_action :authenticate_request

  attr_reader :current_user

  private

  def authenticate_request
    header = request.headers['Authorization']
    token = header.split.last if header
    decoded = JsonWebToken.decode(token)
    @current_user = User.find_by(id: decoded[:user_id]) if decoded
  rescue
    render json: { errors: 'Unauthorized' }, status: :unauthorized
  end

  def authorize_admin!
    render json: { error: 'Forbidden' }, status: :forbidden unless current_user&.admin?
  end
end
