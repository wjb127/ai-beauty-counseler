class ButtonClick < ApplicationRecord
  validates :clicked_at, presence: true
  validates :ip_address, presence: true
  
  scope :today, -> { where(clicked_at: Date.current.beginning_of_day..Date.current.end_of_day) }
  scope :this_week, -> { where(clicked_at: 1.week.ago..Time.current) }
  scope :this_month, -> { where(clicked_at: 1.month.ago..Time.current) }
  scope :recent, -> { order(clicked_at: :desc) }
  
  def self.total_clicks
    count
  end
  
  def self.unique_visitors
    distinct.count(:ip_address)
  end
  
  def self.clicks_by_date(days = 7)
    where(clicked_at: days.days.ago..Time.current)
      .group("DATE(clicked_at)")
      .count
  end
end
