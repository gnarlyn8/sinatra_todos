require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubi"

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
  set :erb, escape_html: true
end

before do
  session[:lists] ||= []
end

def load_list(id)
  list = session[:lists][id]
  return list if list

  session[:error] = "The specified list was not found."
  redirect "/lists"
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
  @list = load_list(@list_id)
  @todos = @list[:todos]

  erb :list
end

post "/lists/:id" do
  list_name = params[:list_name].strip
  @list_id = params[:id].to_i
  @list = load_list(@list_id)

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
  @list = load_list(@list_id)
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
  @list = load_list(@list_id)
  @list[:todos].delete_at(todo_id)
  session[:success] = "Todo has been deleted."

  redirect "/lists/#{params[:id]}"
end

def todo_completed?(todo)
  todo
end

post "/lists/:list_id/todos/:id/toggle" do
  todo_id = params[:id].to_i
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  todo = @list[:todos][todo_id]
  todo[:completed] = !(todo[:completed] == true)

  if todo[:completed]
    session[:success] = "#{todo[:name]} was successfully completed. Good job!"
  else
    session[:error] = "#{todo[:name]} was marked as not done."
  end

  redirect "/lists/#{params[:list_id]}"
end

post "/lists/:id/todos/complete_all" do
  @list_id = params[:id].to_i
  @list = load_list(@list_id)
  @list[:todos].map { |todo| todo[:completed] = true }
  session[:success] = "All todos marked as completed!"

  redirect "/lists/#{params[:id]}"
end

helpers do
  def list_complete?(list)
    todos_remaining_count(list).zero? && total_todos(list) > 0
  end

  def todo_complete?(todo)
    todo[:completed]
  end

  def list_class(list)
    "complete" if list_complete?(list)
  end

  def todos_remaining_count(list)
    list[:todos].select { |todo| !todo[:completed]}.size
  end

  def total_todos(list)
    list[:todos].size
  end

  def sorted_lists(lists, &block)
    incomplete_lists = {}
    completed_lists = {}

    lists.each_with_index do |list, index|
      if list_complete?(list)
        completed_lists[list] = index
      else
        incomplete_lists[list] = index
      end
    end

    incomplete_lists.each(&block)
    completed_lists.each(&block)
  end

  def sorted_todos(todos, &block)
    incomplete_todos = {}
    completed_todos = {}

    todos.each_with_index do |todo, index|
      if todo_complete?(todo)
        completed_todos[todo] = index
      else
        incomplete_todos[todo] = index
      end
    end

    incomplete_todos.each(&block)
    completed_todos.each(&block)
  end
end
