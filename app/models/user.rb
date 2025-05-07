class User < ApplicationRecord
	has_secure_password
	validates :email, :username, :phone_number, uniqueness: true, presence: true
	validates :password, presence: true, confirmation: true
	validates :password_confirmation, presence: true

	has_many :work_sessions, dependent: :destroy
	has_many :screenshots, dependent: :destroy

	def self.ransackable_attributes(auth_object = nil)
		["address", "city", "username", "country", "created_at", "email", "first_name", "id", "id_value", "last_name", "password_digest", "phone_number", "role", "state", "updated_at", "zip_code", "work_sessions_id"]
	end

	def self.ransackable_associations(auth_object = nil)
		[]
	end
end