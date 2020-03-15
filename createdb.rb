# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB = Sequel.connect(connection_string)                                                #
#######################################################################################


# New domain model - adds users
DB.create_table! :restaurants do
  primary_key :id
  String :title
  String :description, text: true
  String :location
end
DB.create_table! :reviews do
  primary_key :id
  foreign_key :restaurant_id
  foreign_key :user_id
  String :date
  Boolean :recommend
  String :comments, text: true
end
DB.create_table! :users do
  primary_key :id
  String :name
  String :email
  String :password
end

# Insert initial (seed) data
restaurants_table = DB.from(:restaurants)

restaurants_table.insert(title: "Mcdonalds", 
                    description: "America's Favorite Fast Food Chain!",
                    location: "Chicago")

restaurants_table.insert(title: "The Really Expensive Steakhouse", 
                    description: "Everything's market price. If you have to ask, you can't afford it",
                    location: "New York City")

puts "Success!"