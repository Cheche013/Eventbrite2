# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

require 'faker'

# Helper to attach a local asset file if present
def attach_file(record, attachment_name, path)
  full = Rails.root.join(path)
  return unless File.exist?(full)
  record.public_send(attachment_name).attach(
    io: File.open(full),
    filename: File.basename(full)
  )
end

# Seed 5 curated items with photos
items_data = [
  { name: 'Pass Concert Vapor', price_cents: 2500, photo: 'app/assets/ui_kit/concert.webp' },
  { name: 'Atelier DJ Starter', price_cents: 1500, photo: 'app/assets/ui_kit/live-music.jpg' },
  { name: 'Soirée Ville Nocturne', price_cents: 3200, photo: 'app/assets/ui_kit/ville-nocturne.png' },
  { name: 'Conf Talk – Chapelier fou', price_cents: 2000, photo: 'app/assets/ui_kit/chapelier-fou-ia.png' },
  { name: 'Expo Alice', price_cents: 1800, photo: 'app/assets/ui_kit/alice-ia.jpg' }
]

items_data.each do |data|
  item = Item.find_or_initialize_by(name: data[:name])
  item.price_cents = data[:price_cents]
  item.save!
  attach_file(item, :photo, data[:photo])
end

# Bonus: create a few demo users with avatars
users = [
  { email: 'alice@example.com', avatar: 'app/assets/ui_kit/alice-ia.jpg' },
  { email: 'chapelier@example.com', avatar: 'app/assets/ui_kit/chapelier-fou-ia.png' }
]

users.each do |u|
  user = User.find_or_initialize_by(email: u[:email])
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.save!
  attach_file(user, :avatar, u[:avatar])
end

puts "Seeded #{Item.count} items and #{User.count} users (with demo avatars)."
