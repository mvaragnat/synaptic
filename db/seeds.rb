# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

if Rails.env.development?
  user = User.create(name: "admin", email: "test@gmail.com",
    password: "password", password_confirmation: "password", admin: "true")
  #topic = Topic.create(subject: "Education")
  element1 = Element.create(title: "Exemple Education 1", address: "http://www.google.com", summary: "Hello World")
  element2 = Element.create(title: "Exemple Education 2", address: "http://www.lemonde.Fr", summary: "Hello World")

  element1.add_or_create_topic("Education")
  element2.add_or_create_topic("Education")

  user.ratings.create(element: element1, value: 1.0)
end
