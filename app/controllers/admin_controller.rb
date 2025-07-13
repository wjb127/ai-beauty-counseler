class AdminController < ApplicationController
  before_action :authenticate_admin, except: [:login]

  def login
    if request.post?
      if params[:password] == 'Simon1793@'
        session[:admin_authenticated] = true
        redirect_to admin_dashboard_path, notice: '로그인 성공!'
      else
        flash.now[:alert] = '비밀번호가 틀렸습니다.'
      end
    end
  end

  def logout
    session[:admin_authenticated] = nil
    redirect_to root_path, notice: '로그아웃되었습니다.'
  end

  def dashboard
    @total_pre_orders = PreOrder.count
    @marketing_consent_count = PreOrder.where(marketing_consent: true).count
    @marketing_consent_rate = @total_pre_orders > 0 ? (@marketing_consent_count.to_f / @total_pre_orders * 100).round(1) : 0

    # 버튼 클릭 통계
    @total_clicks = ButtonClick.total_clicks
    @unique_visitors = ButtonClick.unique_visitors
    @today_clicks = ButtonClick.where(clicked_at: Date.current.all_day).count
    @week_clicks = ButtonClick.where(clicked_at: 1.week.ago..Time.current).count
    
    # 전환율 계산 (사전예약 수 ÷ 총 클릭수)
    @conversion_rate = @total_clicks > 0 ? (@total_pre_orders.to_f / @total_clicks * 100).round(1) : 0

    @pre_orders = PreOrder.order(created_at: :desc)
    @recent_clicks = ButtonClick.order(clicked_at: :desc).limit(10)
  end

  def download_pre_orders
    @pre_orders = PreOrder.order(created_at: :desc)
    
    respond_to do |format|
      format.csv do
        headers['Content-Disposition'] = "attachment; filename=\"pre_orders_#{Date.current}.csv\""
        headers['Content-Type'] = 'text/csv'
      end
    end
  end

  def destroy_pre_order
    @pre_order = PreOrder.find(params[:id])
    @pre_order.destroy
    redirect_to admin_dashboard_path, notice: '사전예약이 삭제되었습니다.'
  end

  def destroy_all_pre_orders
    PreOrder.destroy_all
    redirect_to admin_dashboard_path, notice: '모든 사전예약이 삭제되었습니다.'
  end

  def destroy_button_click
    @button_click = ButtonClick.find(params[:id])
    @button_click.destroy
    redirect_to admin_dashboard_path, notice: '버튼 클릭 기록이 삭제되었습니다.'
  end

  def destroy_all_button_clicks
    ButtonClick.destroy_all
    redirect_to admin_dashboard_path, notice: '모든 버튼 클릭 기록이 삭제되었습니다.'
  end

  private

  def authenticate_admin
    unless session[:admin_authenticated]
      redirect_to admin_login_path
    end
  end
end
