require "sinatra"
require "sinatra/reloader"
require "tilt/erubi"

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

get "/lists" do
  @lists = session[:lists]
  erb :lists
end

get "/lists/new" do
  erb :new_list
end

post "/lists" do
  session[:lists] << {name: params[:list_name], todos: []}
  session[:list_create_success] = "The list has successfully been created!"
  redirect "/lists"
end
