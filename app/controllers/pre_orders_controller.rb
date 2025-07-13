class PreOrdersController < ApplicationController
  def create
    @pre_order = PreOrder.new(pre_order_params)
    
    if @pre_order.save
      render json: { 
        success: true, 
        message: "사전예약이 성공적으로 접수되었습니다!" 
      }
    else
      render json: { 
        success: false, 
        message: "오류가 발생했습니다: #{@pre_order.errors.full_messages.join(', ')}" 
      }
    end
  end

  private

  def pre_order_params
    params.require(:pre_order).permit(:email, :marketing_consent)
  end
end
