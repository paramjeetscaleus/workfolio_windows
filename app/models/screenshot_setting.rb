class ScreenshotSetting < ApplicationRecord
  
  validates :interval, presence: true
  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "id_value", "interval", "updated_at", "user_id"]
  end
end
