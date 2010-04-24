require 'sinatra'
require 'dm-core'
require 'net/http'
require 'uri'
require 'json'

# Configure DataMapper to use the App Engine datastore 
DataMapper.setup(:default, "appengine://auto")

USERNAME = 'ushi3tter_test'
PASSWORD = ''

# model class
class User
  include DataMapper::Resource
  
  property :id, Serial
  property :login, String

  has n, :tls

  def self.test_user
    all.count > 0 ? first : create(:login => USERNAME)
  end
end

class Tl
  include DataMapper::Resource
  
  property :id, Serial
  property :start, DateTime
  property :end, DateTime

  has n, :tweets
end

class Tweet
  include DataMapper::Resource
  
  property :id, Serial
  property :tweet_id, Integer
  property :user_name, String
  property :text, String
  property :created_at, String
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
  @user = User.test_user
  @tl = @user.tls.last if @user.tls

  if @tl
    body = ''
    uri = URI.parse('http://api.twitter.com/1/statuses/home_timeline.json')
    Net::HTTP.start(uri.host, uri.port) do |http|
      request = Net::HTTP::Get.new(uri.request_uri)
      request.basic_auth(USERNAME, PASSWORD)
      http.request(request) do |response|
        body = response.body
        JSON.parse(response.body).each do |status|
          t = Tweet.create(:tweet_id => status['id'].to_i,
                           :user_name => status['user']['name'],
                           :text => status['text'],
                           :created_at => status['created_at'])
          @tl.tweets << t
          @tl.save
          break
        end
      end
    end
  end

  erb :index
end

post '/start' do
  @user = User.test_user
  @user.tls << Tl.create(:start => Time.now)
  @user.save
  session[:message] = "start!"
  redirect '/'
end

post '/stop' do
  @user = User.test_user
  tl = @user.tls.last if @user.tls
  tl.update(:end => Time.now)
  session[:message] = "stop!"
  redirect '/'
end

get '/clear' do
  User.all.destroy
  Tl.all.destroy
  Tweet.all.destroy
  session.clear
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
    ユーザ: <%=h @user.login %><br/>
    <textarea>
    <% if @tl %>
      <% @tl.tweets.each do |t| %>
        <%= t.tweet_id.to_s + t.user_name + t.text + "\n" %>
      <% end %>
    <% end %>
    <%= session[:message] %>
    </textarea>

    <form method="post" action="/start">
      <input type=submit value="おやすみ">
    </form>
    <form method="post" action="/stop">
      <input type=submit value="おはよう！">
    </form>

  </body>
</html>
