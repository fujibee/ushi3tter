require 'appengine-rack'
AppEngine::Rack.configure_app(          
    :application => "ushi3tter",           
    :precompilation_enabled => true,
    :version => "1")
#run lambda { Rack::Response.new("Hello").finish }

require 'app'
run Sinatra::Application
