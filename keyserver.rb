require 'securerandom'
require 'redis'
require 'time'

#set - UNBLOCKED
#sorted set - BLOCKED

class KeyServer

  def initialize(redis)
    @redis = redis
  end


  def generate #O(1)
    random_key = SecureRandom.hex
    if random_key.nil?
      return "Key Generation failed"
    else
      @redis.setex(random_key,300,Time.now)
      @redis.set(random_key,Time.now)
      @redis.sadd('UNBLOCKED',random_key)
      @redis.set(random_key,Time.now)
      return "Key Generated"
    end
  end


   def get #O(logn)
    key = @redis.spop('UNBLOCKED')
    if key.nil?
      temp_array = @redis.zrange('BLOCKED',0,0) # pop last from sorted set
      temp_key = temp_array[0]  
      if temp_key.nil?
        return "No Key"
      else
        if good?(temp_key)
          return temp_key
        else
          #@redis.zadd('BLOCKED',@redis.get(temp_key).to_f,temp_key) #push again
          return "No Key"
        end
      end
  else
    @redis.set(key,Time.now)
    @redis.zadd('BLOCKED',@redis.get(key),key)  
    return key
  end  
  end

  def unblock(key) #O(logn)
    if @redis.exists(key)
      @redis.zrem('BLOCKED',key)
      @redis.sadd('UNBLOCKED',key)
      @redis.set(key,Time.now)
      "Key unblocked"
    else
      "Key not exists"
    end
  end

  def delete(key) #O(logn)
    if @redis.exists(key)
      if @redis.del(key)==1
         if @redis.sismember('UNBLOCK',key)
            @redis.srem('UNBLOCKED',key)
          else
            @redis.zrem('BLOCKED',key)
          end
          "Key deleted"
      else
        "Key unable to delete"
      end
    else
      "Key not exists"
    end
  end


  def keep_alive(key) #O(1)
    if @redis.exists(key)
       @redis.setex(key,300,Time.now)
       @redis.set(key,Time.now)
       "Key life extended"
    else
      "Key not exists"
    end
  end

  def good?(key)
    time_touched = @redis.get(key)
    return (Time.parse(time_touched)-Time.now).abs >= 60
  end
     
end

