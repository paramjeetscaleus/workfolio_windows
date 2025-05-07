class WorkSession < ApplicationRecord
  belongs_to :user
  has_many :screenshots
  # validates :clock_in, presence: true
  has_many :window_usages, dependent: :destroy
  def calculate_total_hours
    return unless clock_in && clock_out
    breaks_duration = break_end && break_start ? (break_end - break_start) : 0
    (clock_out - clock_in - breaks_duration) / 3600.0
  end
end
