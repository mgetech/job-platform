class AuthController < ApplicationController
  skip_before_action :authenticate_request, only: [:register, :login]

  def register
    user = User.new(register_params)
    if user.save
      render json: { token: JsonWebToken.encode(user_id: user.id), role: user.role }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def login
    user = User.find_by(username: params[:username])
    if user&.authenticate(params[:password])
      render json: { token: JsonWebToken.encode(user_id: user.id), role: user.role }, status: :ok
    else
      render json: { error: 'Invalid credentials' }, status: :unauthorized
    end
  end

  private

  def register_params
    params.permit(:name, :username, :password)
  end
end