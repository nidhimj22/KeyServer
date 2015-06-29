require 'securerandom'
#require 'redis'

#set - UNBLOCKED
#list - BLOCKED

class KeyServer

  def initialize
  end


  def generate(redis) #O(1)
    random_key = SecureRandom.hex
    if random_key.nil?
      "Key Generation failed"
    end
    redis.setex(random_key,300,Time.now) 
    redis.sadd('UNBLOCKED',random_key) #unblocked set (unsorted set)
    "Key Generated"
  end


  def get(redis) #O()
    key = redis.spop('UNBLOCKED')
    if key.nil?
      key = key_from_blocked(redis) #amortized O(1) complexity
    else
      redis.set(key,Time.now)
      redis.lpush('BLOCKED',key) 
    end
    key
  end

  def unblock(redis,key)
    if redis.exists(key)
      redis.lrem('BLOCKED',1,key)
      redis.sadd('UNBLOCKED',key)
      "Key unblocked"
    else
      "Key not exists"
    end
  end

  def delete(redis,key)
    if redis.exists(key)
      if redis.del(key)==1
          redis.srem('UNBLOCKED',key) 
          redis.lrem('BLOCKED',1,key)
          "Key deleted"
      else
        "Key unable to delete"
      end
    else
      "Key not exists"
    end
  end


  def keep_alive(redis,key)
    if redis.exists(key)
       redis.setex(key,300,Time.now)
       "Key life extended"
    else
      "Key not exists"
    end
  end


  def key_from_blocked(redis)
    temp_key = redis.rpop('BLOCKED')

    if temp_key.nil?
      nil
    else
      temp_key_time = redis.get(temp_key)
      if (Time.parse(temp_key_time)-Time.now).abs >=60
        redis.lpush('BLOCKED',temp_key)
        redis.set(temp_key,Time.now)
        key
      else
        redis.rpush('BLOCKED',temp_key)
        nil
      end
    end

  end
end

=begin
redis = Redis.new
redis.flushall
key_server = KeyServer.new
puts key_server.generate(redis)
puts key_server.get(redis)
=end
