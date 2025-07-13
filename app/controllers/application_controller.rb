class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  def current_user
    # 현재는 로그인 기능이 없으므로 nil 반환
    nil
  end

  helper_method :current_user
end
