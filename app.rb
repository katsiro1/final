# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"                                                                     #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "twilio-ruby"                                                                 #
require "bcrypt"                                                               #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################
require "geocoder"

restaurants_table = DB.from(:restaurants)
reviews_table = DB.from(:reviews)
users_table = DB.from(:users)

before do
    @current_user = users_table.where(id: session["user_id"]).to_a[0]
end

# homepage and list of events (aka "index")
get "/" do
    puts "params: #{params}"

    @restaurants = restaurants_table.all.to_a
    pp @restaurants

    view "restaurants"
end

get "/restaurants/new" do
    view "new_restaurant"
end



# event details (aka "show")
get "/restaurants/:id" do
    puts "params: #{params}"

    @users_table = users_table
    @restaurant = restaurants_table.where(id: params[:id]).to_a[0]
    pp @restaurant

    @reviews = reviews_table.where(restaurant_id: @restaurant[:id]).to_a
    recommend_count = reviews_table.where(restaurant_id: @restaurant[:id], recommend: true).count
    review_count = reviews_table.where(restaurant_id: @restaurant[:id]).count
    if review_count == 0
        then @recommend_percent = 0
    else
        @recommend_percent = 100 * recommend_count / review_count
    end
    results = Geocoder.search(@restaurant[:location])
    coordinates = results.first.coordinates # => [lat, long]
    @lat = coordinates[0]
  @long = coordinates[1]
  @lat_long = "#{@lat},#{@long}"
    view "restaurant"
end

post "/restaurants/create" do
    puts "params: #{params}"
  
    restaurants_table.insert(
        title: params["title"],
        location: params["location"]
    )

    view "create_restaurant"
end


get "/restaurants/:id/reviews/new" do
    puts "params: #{params}"


    @restaurant = restaurants_table.where(id: params[:id]).to_a[0]
view "new_review"
end

post "/restaurants/:id/reviews/create" do
    puts "params: #{params}"

    @restaurant = restaurants_table.where(id: params[:id]).to_a[0]
  
    reviews_table.insert(
        restaurant_id: @restaurant[:id],
        user_id: session["user_id"],
        date: params["date"],
        comments: params["comments"],
        recommend: params["recommend"]
    )

    redirect "/restaurants/#{@restaurant[:id]}"
end

get "/reviews/:id/edit" do
    puts "params: #{params}"

    @review = reviews_table.where(id: params["id"]).to_a[0]
    @restaurant = restaurants_table.where(id: @review[:restaurant_id]).to_a[0]
    view "edit_review"
end

post "/reviews/:id/update" do
    puts "params: #{params}"

    @review = reviews_table.where(id: params["id"]).to_a[0]
    
    @restaurant = restaurants_table.where(id: @review[:restaurant_id]).to_a[0]

    if @current_user && @current_user[:id] == @review[:id]
        reviews_table.where(id: params["id"]).update(
            recommend: params["recommend"],
            comments: params["comments"]
        )

        redirect "/restaurants/#{@restaurant[:id]}"
    else
        view "error"
    end
end


get "/reviews/:id/destroy" do
    puts "params: #{params}"

    review = reviews_table.where(id: params["id"]).to_a[0]
    @restaurant = restaurants_table.where(id: review[:restaurant_id]).to_a[0]

    reviews_table.where(id: params["id"]).delete

    redirect "/restaurants/#{@restaurant[:id]}"
end

# display the signup form (aka "new")
get "/users/new" do
    view "new_user"
end

# receive the submitted signup form (aka "create")
post "/users/create" do
    puts "params: #{params}"

    # if there's already a user with this email, skip!
    existing_user = users_table.where(email: params["email"]).to_a[0]
    if existing_user
        view "error"
    else
        users_table.insert(
            name: params["name"],
            email: params["email"],
            password: BCrypt::Password.create(params["password"])
        )

        redirect "/logins/new"
    end
end

# display the login form (aka "new")
get "/logins/new" do
    view "new_login"
end

# receive the submitted login form (aka "create")
post "/logins/create" do
    puts "params: #{params}"

    # step 1: user with the params["email"] ?
    @user = users_table.where(email: params["email"]).to_a[0]

    if @user
        # step 2: if @user, does the encrypted password match?
        if BCrypt::Password.new(@user[:password]) == params["password"]
            # set encrypted cookie for logged in user
            session["user_id"] = @user[:id]
            redirect "/"
        else
            view "create_login_failed"
        end
    else
        view "create_login_failed"
    end
end

# logout user
get "/logout" do
    # remove encrypted cookie for logged out user
    session["user_id"] = nil
    redirect "/logins/new"
end


