require 'securerandom'
#require 'redis'

class KeyServer
  
  def initialize  
  end


  def generate(redis)
    random_key = SecureRandom.hex
    redis.sadd('UNBLOCKED',random_key)
    redis.setex(random_key,300,Time.now)

    if random_key.nil?
      "Key Generation failed"
    else
      "Key Generated"
    end

  end
  

  def get(redis)
    key = redis.spop('UNBLOCKED')
    if key.nil?
      key = get_expired_key(redis)
    else 
      redis.set(key,Time.now)
      redis.lpush('BLOCKED',key) 
    end
    key
  end
   
  def unblock(redis,key)
    if redis.exists(key)     
      if redis.sadd('UNBLOCKED',key)
         redis.lrem('BLOCKED',1,key) 
         "Key unblocked"
      else
        "Key unblocked"
      end
    else
      "Key not exists"
    end
  end

  def delete(redis,key)

    if redis.exists(key)
      if redis.del(key)==1
        if redis.sismember('UNBLOCKED',key)
	  redis.srem('UNBLOCKED',key)
	end               
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

    
  def get_expired_key(redis)
    key = redis.rpop('BLOCKED')
    if not key.nil?
      time_stamp = redis.get(key)
      if (Time.parse(time_stamp)-Time.now).abs >=60
        redis.lpush('BLOCKED',key)
        redis.set(key,Time.now)
        key
      else
        redis.rpush('BLOCKED',key)
        nil
      end
    end 
    nil     
  end
end

=begin
redis = Redis.new
redis.flushall
key_server = KeyServer.new
puts key_server.generate(redis)
puts key_server.get(redis)
=end
