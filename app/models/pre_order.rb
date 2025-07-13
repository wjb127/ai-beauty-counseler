class PreOrder < ApplicationRecord
  validates :email, presence: true, 
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { case_sensitive: false }
  
  before_save :downcase_email
  
  scope :with_marketing_consent, -> { where(marketing_consent: true) }
  scope :recent, -> { order(created_at: :desc) }

  private

  def downcase_email
    self.email = email.downcase if email.present?
  end
end
