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

use Rack::Session::Cookie,
  :expire_after => 3600,
  :secret => 'change'

get '/' do
  @users = User.all
  erb :index
end

post '/start' do
  session[:message] = "start!"
  redirect '/'
end

post '/stop' do
  session[:message] = "stop!"
  redirect '/'
end

#  shout = Shout.create(:message => params[:message])
#    <% @users.each do |u| %>
#    <p><q><%=h u.login %></q></p>
#    <% end %>
__END__

@@ index
<html>
  <head>
    <title>丑三つったー</title>
  </head>
  <body style="font-family: sans-serif;">
    <h1>丑三つったー</h1>
    <%=h session[:message] %>

    <form method="post" action="/start">
      <input type=submit value="おやすみ">
    </form>
    <form method="post" action="/stop">
      <input type=submit value="おはよう！">
    </form>

    <div style="position: absolute; bottom: 20px; right: 20px;">
    <img src="/images/appengine.gif"></div>
  </body>
</html>
