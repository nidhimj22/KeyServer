require 'securerandom'
require 'redis'

#set - UNBLOCKED
#sorted set - BLOCKED

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
    @redis.set(random_key,Time.now)
    @redis.sadd('UNBLOCKED',random_key)
    "Key Generated"
  end


  def get #O(logn)
    key = @redis.spop('UNBLOCKED')
    if key.nil?
      key = key_from_blocked
      if key.nil?
        nil
      end
    else
      @redis.set(key,Time.now)
      @redis.zadd('BLOCKED',@redis.get(key).to_f,key)
    end
    key
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


  def key_from_blocked #O(logn)
    temp_key = @redis.zremrangebyrank('BLOCKED',0,0) # pop last from sorted set

    if temp_key.nil?
      nil
    else
      temp_key_time = @redis.get(temp_key)
      if temp_key_time.nil?
        @redis.sadd('UNBLOCKED',temp_key)
        @redis.set(temp_key,Time.now)
        temp_key
      else
        if (Time.parse(temp_key_time)-Time.now).abs >=60
          @redis.sadd('UNBLOCKED',temp_key)
          @redis.set(key,Time.now)
          temp_key
        else
          @redis.zadd('BLOCKED',@redis.get(temp_key).to_f,temp_key) #push again
          nil
        end
      end
    end

  end
end

