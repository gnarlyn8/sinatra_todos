require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubi"
require 'pry'

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
    session[:error] = error
    erb :new_list
  else
    session[:lists] << {name: list_name, todos: []}
    session[:success] = "The list has successfully been created!"
    redirect "/lists"
  end
end

get "/lists/:id" do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  @todos = @list[:todos]

  erb :list
end

post "/lists/:id" do
  list_name = params[:list_name].strip
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]

  if (error = error_for_list_name(list_name))
    session[:error] = error
    erb :edit_list
  else
    @list[:name] = list_name
    session[:success] = "The list has successfully updated!"
    redirect "/lists/#{params[:id]}"
  end
end

get "/lists/:id/edit" do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]

  erb :edit_list
end

post "/lists/:id/delete" do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  session[:lists].delete_at(@list_id)
  session[:success] = "#{@list[:name]} was successfully deleted."

  redirect "/lists"
end

def error_for_todo(todo)
  if !todo.size.between?(1, 100)
    "Todo must contain between 1 and 100 characters"
  end
end

post "/lists/:id/todos" do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  @todos = @list[:todos]
  todo = params[:todo]

  if (error = error_for_todo(todo))
    session[:error] = error
    erb :list
  else
    @list[:todos] << {name: todo, completed: false}
    session[:success] = "#{todo} was successfully added to list."
    redirect "/lists/#{params[:id]}"
  end
end

post "/lists/:id/todos/:index/destroy" do
  todo_id = params[:index].to_i
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  @list[:todos].delete_at(todo_id)
  session[:success] = "Todo has been deleted."

  redirect "/lists/#{params[:id]}"
end

def todo_completed?(todo)
  todo
end

post "/lists/:id/todos/:index/toggle" do
  todo_id = params[:index].to_i
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  todo = @list[:todos][todo_id]
  todo[:completed] = !(todo[:completed] == true)

  if todo[:completed]
    session[:success] = "#{todo[:name]} was successfully completed. Good job!"
  else
    session[:error] = "#{todo[:name]} was marked as not done."
  end

  redirect "/lists/#{params[:id]}"
end
