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

  has n, :tweets, :order => [ :created_at.asc ]
end

class Tweet
  include DataMapper::Resource
  
  property :id, Serial
  property :tweet_id, Integer
  property :user_name, String
  property :user_image_url, String
  property :text, String
  property :created_at, String
end

# Make sure our template can use <%=h
helpers do
  include Rack::Utils
  alias_method :h, :escape_html

  def convert_time(time)
    Time.at(Time.parse(time).to_i + 9 * 3600).strftime("%Y/%m/%d %H:%M")
  end
end

use Rack::Session::Cookie,
  :expire_after => 3600,
  :secret => 'change'

get '/' do
  @user = User.test_user
  if session[:status] == :stop
    @tl = @user.tls.last if @user.tls
  end
  erb :index
end

get '/fetch' do
  fetch_tl
  redirect '/'
end

def fetch_tl
  @user = User.test_user
  @tl = @user.tls.last if @user.tls

  if @tl
    uri = URI.parse('http://api.twitter.com/1/statuses/home_timeline.json')
    Net::HTTP.start(uri.host, uri.port) do |http|
      request = Net::HTTP::Get.new(uri.request_uri)
      request.basic_auth(USERNAME, PASSWORD)
      http.request(request) do |response|
        JSON.parse(response.body).each do |status|
          new_tweet = Tweet.new(:tweet_id => status['id'].to_i,
                                :user_name => status['user']['screen_name'],
                                :user_image_url => status['user']['profile_image_url'],
                                :text => status['text'],
                                :created_at => status['created_at'])
          exists = false
          @tl.tweets.each do |t|
            if t.tweet_id == new_tweet.tweet_id
              exists = true
              break
            end
          end
          break if exists
          @tl.tweets << new_tweet
        end
        @tl.save
      end
    end
  end
end

post '/start' do
  clear

  @user = User.test_user
  @user.tls << Tl.create(:start => Time.now)
  @user.save
  
  fetch_tl

  session[:status] = :start
  redirect '/'
end

post '/stop' do
  @user = User.test_user
  tl = @user.tls.last if @user.tls
  tl.update(:end => Time.now)

  fetch_tl

  session[:status] = :stop
  redirect '/'
end

get '/clear' do
  clear
  redirect '/'
end

def clear
  User.all.destroy
  Tl.all.destroy
  Tweet.all.destroy
  session.clear
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

    <% if session[:status] != :start %>

    あなたが寝ている間(たとえ丑三つ時でも)の、あなたのTLに流れるtweetを起きたときまで保存します。安心しておやすみください！<br/>

    ユーザ: <a href="http://twitter.com/<%=h @user.login %>"><%=h @user.login %></a> (現在はこのユーザのみです。)<br/>

    <form method="post" action="/start">
      <input type=submit value="おやすみ">
    </form>
    
    <% else %>

    あなたのTLを保存しています。。<a href="/fetch">手動保存</a>
    <form method="post" action="/stop">
      <input type=submit value="おはよう！">
    </form>

    <% end %>

    <% if @tl %>
      あなたの寝てた間のTLです。
      <table>
      <% @tl.tweets.each do |t| %>
        <tr style="color: gray; font-size: 14px;">
        <td colspan="2"><%= convert_time(t.created_at) %></td>
        </tr>
        <tr style="font-size: 14px;">
          <td><img src="<%= t.user_image_url %>"></td>
          <td><a href="http://twitter.com/<%= t.user_name %>"><%= t.user_name %></a> <%= t.text %></td>
        </tr>
        <tr><td colspan="2" style="border-bottom: thin solid gray;"></td></tr>
      <% end %>
      </table>
    <% end %>

  <div style="color: gray; font-size: 14px; textr-align: right;">
  Created by <a href="http://twitter.com/fujibee">@fujibee</a>. Powered by Google App Engine for Java and <a href="http://code.google.com/p/appengine-jruby/">google-appengine for JRuby</a> + <a href="http://www.sinatrarb.com/">sinatra</a>
  </div>
  </body>
</html>
