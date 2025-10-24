require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubi"
require "pry"

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

def error_for_list_name(list_name)
  if !list_name.size.between?(1, 100)
    "List name must contain between 1 and 100 characters"
  elsif session[:lists].any? { |list| list[:name] == list_name }
    "List name must be unique"
  end
end

post "/lists" do
  list_name = params[:list_name].strip

  if (error = error_for_list_name(list_name))
    session[:list_create_error] = error
    erb :new_list
  else
    session[:lists] << {name: list_name, todos: []}
    session[:list_success] = "The list has successfully been created!"
    redirect "/lists"
  end
end

get "/lists/:id" do
  list_id = params[:id].to_i
  @list = session[:lists][list_id]

  erb :list
end

post "/lists/:id" do
  list_name = params[:list_name].strip
  list_id = params[:id].to_i
  @list = session[:lists][list_id]

  if (error = error_for_list_name(list_name))
    session[:list_create_error] = error
    erb :edit_list
  else
    @list[:name] = list_name
    session[:list_success] = "The list has successfully updated!"
    redirect "/lists/:id"
  end
end

get "/lists/:id/edit" do
  list_id = params[:id].to_i
  @list = session[:lists][list_id]

  erb :edit_list
end

post "/lists/:id/delete" do
  list_id = params[:id].to_i
  @list = session[:lists][list_id]
  session[:lists].delete_at(list_id)
  session[:list_success] = "#{@list[:name]} was successfully deleted."

  redirect "/lists"
end
