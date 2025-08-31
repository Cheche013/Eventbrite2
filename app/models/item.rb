class Item < ApplicationRecord
  has_one_attached :photo

  def price_eur
    (price_cents || 0) / 100.0
  end
end
