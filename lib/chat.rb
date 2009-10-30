require 'redis'
require 'json'
require 'time'

module Chat

  class ChatError < StandardError; end
  class UserNotFound < ChatError; end

  class Database

    def initialize(namespace)
      @namespace = namespace
      @db = Redis.new
    end

    def namespace_key(*names)
      ([ 'Chat', @namespace ] + names).join(":")
    end

    def method_missing(method, key, *args, &block)
      @db.send(method, namespace_key(key), *args, &block)
    end

  end # Database

  # Represents a class room
  class Room
    attr_reader :name

    def initialize(name)
      @name = name
      @db = Database.new(name)
      @messages = Messages.new(@db)
    end

    # members

    def join(nickname)
      @db.sadd :members, nickname
    end

    def leave(nickname)
      @db.srem :members, nickname
    end

    def members
      @db.smembers :members
    end

    def include?(nickname)
      @db.sismember :members, nickname
    end

    # messages

    def say(nickname, message)
      raise UserNotFound unless include?(nickname)
      @messages << Message.new(nickname, message, Time.now)
    end

    def messages
      @messages
    end

  end # Room


  # Message list
  class Messages
    include Enumerable

    def initialize(db)
      @db = db
    end

    def [](index, offset=nil)
      if offset # range
        @db.lrange(:messages, index, offset).map! { |message| JSON message }
      else
        message = @db.lindex(:messages, index)
        JSON message if message
      end
    end

    def <<(message)
      @db.rpush(:messages, JSON(message))
    end

    def clear
      @db.del :messages
    end

    def size
      @db.llen :messages
    end

    def each(&block)
      self[0, -1].each { |message| yield(message) }
    end

  end # Messages


  # A chat message serialized with JSON
  class Message < Struct.new(:nickname, :text, :created_at)

    def to_json(*a)
      {
        'json_class'  => self.class.name,
        'data'        => [ nickname, text, created_at.to_s ]
      }.to_json(*a)
    end

    def self.json_create(o)
      nickname, text, created_at = *o['data']
      new(nickname, text, Time.parse(created_at))
    end

  end

end
