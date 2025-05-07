class ScreenshotsController < ApplicationController
  skip_before_action :verify_authenticity_token # skip CSRF for external API

  def create_from_python
    # debugger
    screenshot = Screenshot.new(
      user_id: params[:user_id].to_i,
      file_path: params[:file_path],
      created_at: params[:created_at] || Time.current
    )

    if screenshot.save
      render json: { status: "success", id: screenshot.id }, status: :created
    else
      render json: { status: "error", errors: screenshot.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
