class PagesController < ApplicationController
  def home
  end

  def update_time
    render turbo_frame: "dynamic_content"
  end
end
