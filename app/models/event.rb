class Event < ApplicationRecord
  belongs_to :admin, class_name: "User"   # adapte si ton association s’appelle différemment
  has_many :attendances, dependent: :destroy
  has_many :attendees, through: :attendances, source: :user

  def is_free?
    (price_cents || 0).to_i == 0
  end

  def price_eur
    (price_cents || 0) / 100.0
  end

  def participant?(user)
    attendees.exists?(user.id)
  end
end
