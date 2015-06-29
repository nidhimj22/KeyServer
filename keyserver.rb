require 'securerandom'
require 'redis'

#set - UNBLOCKED
#list - BLOCKED

class KeyServer

  def initialize(redis)
    @redis = redis
  end


  def generate #O(1)
    random_key = SecureRandom.hex
    if random_key.nil?
      "Key Generation failed"
    end
    @redis.setex(random_key,300,Time.now) 
    @redis.sadd('UNBLOCKED',random_key) #unblocked set (unsorted set)
    "Key Generated"
  end


  def get #O()
    key = @redis.spop('UNBLOCKED')
    if key.nil?
      key = key_from_blocked #amortized O(1) complexity
    else
      @redis.set(key,Time.now)
      @redis.lpush('BLOCKED',key) 
    end
    key
  end

  def unblock(key)
    if @redis.exists(key)
      @redis.lrem('BLOCKED',1,key)
      @redis.sadd('UNBLOCKED',key)
      "Key unblocked"
    else
      "Key not exists"
    end
  end

  def delete(key)
    if @redis.exists(key)
      if @redis.del(key)==1
          @redis.srem('UNBLOCKED',key) 
          @redis.lrem('BLOCKED',1,key)
          "Key deleted"
      else
        "Key unable to delete"
      end
    else
      "Key not exists"
    end
  end


  def keep_alive(key)
    if @redis.exists(key)
       @redis.setex(key,300,Time.now)
       "Key life extended"
    else
      "Key not exists"
    end
  end


  def key_from_blocked
    temp_key = @redis.rpop('BLOCKED')

    if temp_key.nil?
      nil
    else
      temp_key_time = @redis.get(temp_key)
      if (Time.parse(temp_key_time)-Time.now).abs >=60
        @redis.lpush('BLOCKED',temp_key)
        @redis.set(temp_key,Time.now)
        temp_key
      else
        @redis.rpush('BLOCKED',temp_key)
        nil
      end
    end

  end
end

