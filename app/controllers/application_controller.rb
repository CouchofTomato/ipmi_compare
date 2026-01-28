class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  def require_admin!
    return if current_user&.admin?

    redirect_to root_path, alert: "You are not authorized to access that page."
  end
end
