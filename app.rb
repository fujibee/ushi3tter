require 'sinatra'
require 'dm-core'
require 'net/http'
require 'uri'
require 'json'

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
  session[:message] = ""
  erb :index
end

USERNAME = 'ushi3tter_test'
PASSWORD = ''
get '/tl' do
  uri = URI.parse('http://api.twitter.com/1/statuses/home_timeline.json')
  Net::HTTP.start(uri.host, uri.port) do |http|
    request = Net::HTTP::Get.new(uri.request_uri)
    request.basic_auth(USERNAME, PASSWORD)
    http.request(request) do |response|
      str = ''
      JSON.parse(response.body).each do |status|
        str += status['screen_name'] if status['screen_name']
        str += ':'
        str += status['text'] if status['text']
        str += '<br>'
      end
      session[:message] = str
    end
  end
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
#    <div style="position: absolute; bottom: 20px; right: 20px;">
#    <img src="/images/appengine.gif"></div>
__END__

@@ index
<html>
  <head>
    <title>丑三つったー</title>
  </head>
  <body style="font-family: sans-serif;">
    <h1>丑三つったー</h1>
    <%= session[:message] %>

    <form method="post" action="/start">
      <input type=submit value="おやすみ">
    </form>
    <form method="post" action="/stop">
      <input type=submit value="おはよう！">
    </form>

  </body>
</html>
