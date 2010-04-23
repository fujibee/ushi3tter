require 'sinatra'
require 'dm-core'

# Configure DataMapper to use the App Engine datastore 
DataMapper.setup(:default, "appengine://auto")

# model class
class User
  include DataMapper::Resource
  
  has n, :tls
  property :login, String
end

class Tl
  include DataMapper::Resource
  
  has n, :tweets
  property :start, DateTime
  property :end, DateTime
end

class Tweet
  include DataMapper::Resource
  
  property :user_id, Integer
  property :text, String
end

# Make sure our template can use <%=h
helpers do
  include Rack::Utils
  alias_method :h, :escape_html
end

get '/' do
  @users = User.all
  erb :index
end

post '/start' do
#  shout = Shout.create(:message => params[:message])
  redirect '/'
end

post '/stop' do
  redirect '/'
end

__END__

@@ index
<html>
  <head>
    <title>丑三つったー</title>
  </head>
  <body style="font-family: sans-serif;">
    <h1>Test</h1>

    <form method=post>
      <textarea name="message" rows="3"></textarea>
      <input type=submit value="おやすみ">
    </form>

    <% @users.each do |u| %>
    <p><q><%=h u.login %></q></p>
    <% end %>

    <div style="position: absolute; bottom: 20px; right: 20px;">
    <img src="/images/appengine.gif"></div>
  </body>
</html>
