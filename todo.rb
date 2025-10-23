require "sinatra"
require "sinatra/reloader"
require "tilt/erubi"

before do
  @lists = [
    {name: "New list", todos: []},
    {name: "New list 2", todos: []}
  ]
end

get "/" do
  redirect "/lists"
end

get "/lists" do
  erb :lists
end
