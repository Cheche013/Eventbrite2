class Event < ApplicationRecord
  # events.user_id points to the event creator/admin
  belongs_to :admin, class_name: "User", foreign_key: :user_id
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

   has_one_attached :photo

  validate :photo_must_be_attached

  private
  def photo_must_be_attached
    errors.add(:photo, "doit être jointe") unless photo.attached?
  end
end
