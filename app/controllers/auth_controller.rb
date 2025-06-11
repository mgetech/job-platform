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


  def update_role
    user_to_update = User.find_by(email: params[:email])

    if user_to_update.nil?
      render json: { errors: "User with email '#{params[:email]}' not found" }, status: :not_found
      return
    end

    unless User.roles.keys.include?(params[:role])
      render json: { errors: "Invalid role specified" }, status: :unprocessable_entity
      return
    end

    if user_to_update.update(role: params[:role])
      render json: { message: "User role updated successfully", user: { id: user_to_update.id, email: user_to_update.email, role: user_to_update.role } }, status: :ok
    else
      render json: { errors: user_to_update.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def register_params
    params.permit(:name, :email, :password)
  end

  def user_params
    params.permit(:email, :password)
  end

  def role_params
    params.permit(:email, :role)
  end
end