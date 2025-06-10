class AuthController < ApplicationController
  skip_before_action :authenticate_request!, only: [:register, :login]

  def register
    user = User.new(register_params)
    if user.save
      render json: { token: JsonWebToken.encode(user_id: user.id), role: user.role }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def login
    user = User.find_by(email: params[:email])
    if user&.authenticate(params[:password])
      render json: { token: JsonWebToken.encode(user_id: user.id), role: user.role }, status: :ok
    else
      render json: { error: 'Invalid credentials' }, status: :unauthorized
    end
  end

  private

  def register_params
    params.permit(:name, :email, :password)
  end

  def user_params
    params.permit(:email, :password)
  end
end