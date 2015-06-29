$LOAD_PATH << File.dirname(__FILE__)

require 'rubygems'
require 'sinatra'
require 'keyserver'
require 'redis'

set :port, 9830

redis = Redis.new
redis.flushall
key_server = KeyServer.new(redis)


get '/' do
  "KeyServer Started"
end


get '/generate' do
  key_server.generate
end


get '/get' do
  key = key_server.get
  if key.nil?
    "Wait No Key got"
  end
    key
end


get '/unblock/:key' do
  key_server.unblock(params['key'])
end


get '/delete/:key' do
  key_server.delete(params['key'])
end


get '/keep_alive/:key' do
  key_server.keep_alive(params['key'])
end


not_found do
  "Page not found - 404"
end

