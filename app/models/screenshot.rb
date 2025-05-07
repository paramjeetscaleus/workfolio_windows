class Screenshot < ApplicationRecord
  belongs_to :user  
  # For Active Storage (if you want to store the actual file in the database)
  has_one_attached :image
  
  validates :user_id, presence: true

  def self.ransackable_associations(auth_object = nil)
    ["image_attachment", "image_blob", "user", "work_session"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "file_path", "id", "id_value", "updated_at", "user_id"]
  end
end