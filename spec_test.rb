$LOAD_PATH << File.dirname(__FILE__)

require 'rubygems'
require 'sinatra'
require 'redis'
require 'main'
require 'keyserver'

redis = Redis.new
redis.flushall
key_server=KeyServer.new(redis)

describe "MainTest" do

  before(:all) do
    puts "==================RSPEC TESTS TO CHECK ENDPOINTS==========================="

  end

  it "checks generate_key endpoint" do
    expect(key_server.generate).to match(/Key Generated/)
  end

  it "checks get_key endpoint" do
    key_server.generate
    key = key_server.get
    expect(key).to match(/[a-f0-9]*/)
  end

  it "checks unblock_key endpoint" do
    key_server.generate
    key = key_server.get
    expect(key_server.unblock(key)).to match(/Key unblocked/)
  end

  it "checks unblock_key endpoint" do
    expect(key_server.unblock("ac0dffd5acbbeb637dd987500a8b9528")).to match(/Key not exists/)
  end

  it "checks delete_key endpoint" do
    expect(key_server.delete("ac0dffd5acbbeb637dd987500a8b9528")).to match(/Key not exists/)
  end

  it "checks delete_key endpoint" do
    key_server.generate
    key = key_server.get
    expect(key_server.delete(key)).to match(/Key deleted/)
  end

  it "checks keep_alive endpoint" do
    key_server.generate
    key = key_server.get
    expect(key_server.keep_alive(key)).to match(/Key life extended/)
  end

  it "checks keep_alive endpoint" do
    expect(key_server.keep_alive("ac0dffd5acbbeb637dd987500a8b9528")).to match(/Key not exists/)
  end

end

