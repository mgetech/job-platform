class LanguagesController < ApplicationController
  skip_before_action :authenticate_request!, only: [:index]

  def index
    languages = Language.all
    render json: languages.select(:id, :name), status: :ok
  end
end