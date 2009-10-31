require 'rubygems'
require 'sinatra'

require 'chat'

helpers do
  def logged_in?
    !request.cookies["name"].nil?
  end

  def login_name
    request.cookies["name"]
  end

  def require_name
    redirect "/login" unless logged_in?
  end
end

get '/' do
  require_name
  @name = login_name
  erb :index
end

get '/login' do
  redirect '/' if logged_in?
  erb :login
end

post '/login' do
  redirect '/' if logged_in?
  if params[:name]
    set_cookie("name", params[:name])
    redirect '/'
  else
    erb :login
  end
end

get '/logout' do
  require_name
  delete_cookie("name")
  redirect '/'
end

get '/room/:name' do
  require_name
  @name = login_name
  @chat = Chat::Room.new(params[:name])
  @chat.join(@name)
  @room_name = @chat.name
  @messages = @chat.messages
  erb :room
end

post '/room' do
  require_name
  name = params[:room]
  if name && !name.empty?
    redirect "/room/#{name}"
  else
    redirect "/"
  end
end

get '/say/:name' do
  redirect "/room/#{params[:name]}"
end

post '/say/:name' do
  require_name
  text = params[:text]
  if text && !text.empty?
    @chat = Chat::Room.new(params[:name])
    @chat.join(login_name)
    @chat.say(login_name, text)
  end
  redirect "/room/#{@chat.name}"
end

__END__

@@layout
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
  <head>
    <title>Chat</title>
  </head>
  <body>
    <div id="content">
      <% if logged_in? %>
        <p>Hi <%= @name %> <a href="/logout">logout</a></p>
      <% end %>
      <%= yield %>
    </div>
  </body>
</html>

@@index

<form action="/room" method="post">
  <label for="room">Room</label>
  <input type="text" name="room" />
  <input type="submit" value="Join" />
</form>

@@login

<form action="/login" method="post">
  <label for="name">Name</label>
  <input type="text" name="name" value=""/>

  <input type="submit" value="Login"/>
</form>

@@ room

<h2>Room <%= @room_name %></h2>

<div id="messages">
  <% for message in @messages %>
    <div title="<%= message.created_at %>">
      <strong><%= message.nickname %></strong>
      <span><%= message.text %></span>
    </div>
  <% end %>
</div>

<form action="/say/<%= @room_name %>" method="post">
  <label for="text"><%= @name %></label>
  <input type="text" name="text" />

  <input type="submit" value="Chat"/>
</form>
