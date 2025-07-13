class ButtonClicksController < ApplicationController
  def create
    @button_click = ButtonClick.new(
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      clicked_at: Time.current
    )
    
    if @button_click.save
      render json: { 
        success: true, 
        message: "클릭이 기록되었습니다." 
      }
    else
      render json: { 
        success: false, 
        message: "클릭 기록에 실패했습니다." 
      }
    end
  end
end
