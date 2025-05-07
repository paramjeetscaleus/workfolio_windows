class WindowUsage < ApplicationRecord
  belongs_to :work_session

  def self.ransackable_associations(auth_object = nil)
    ["work_session"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "duration", "id", "id_value", "percentage", "updated_at", "window_title", "work_session_id"]
  end
end
