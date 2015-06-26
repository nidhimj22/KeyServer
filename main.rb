$LOAD_PATH << File.dirname(__FILE__)

require 'rubygems'
require 'sinatra'
require 'keyserver'
require 'redis'

set :port, 9830

redis = Redis.new
redis.flushall
key_server = KeyServer.new

get '/' do
  "KeyServer Started"
end


get '/generate' do
  key_server.generate(redis)
end


get '/get' do
  key = key_server.get(redis)
  key
end


get '/unblock/:key' do
  key_server.unblock(redis,params['key'])
end


get '/delete/:key' do
  key_server.delete(redis,params['key'])
end


get '/keep_alive/:key' do
  key_server.keep_alive(redis,params['key'])
end


not_found do
  "Page not found - 404"
end

