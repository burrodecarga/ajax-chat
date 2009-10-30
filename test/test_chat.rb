require 'helper'

context "chat" do

  context "database" do
    setup do
      @db1 = Chat::Database.new("name1")
      @db2 = Chat::Database.new("name2")
      @db1["test"] = "test1"
      @db2["test"] = "test2"
    end

    asserts("get var for name1") { @db1["test"] }.equals("test1")
    asserts("get var for name2") { @db2["test"] }.equals("test2")
  end

  context "basic room" do
    setup do
      @room = Chat::Room.new("test1")
    end

    asserts("has name") { @room.name }.equals("test1")
    asserts("no members") { @room.members.size }.equals(0)
  end

  context "room with members" do
    setup do
      @room = Chat::Room.new("test2")
      @room.messages.clear
      @room.join "alice"
      @room.join "bob"
    end

    asserts("has members") { @room.members.sort }.equals(%w(alice bob))
    asserts("contains alice") { @room.include?("alice") }
    asserts("contains bob") { @room.include?("bob") }

    asserts("has less members") do
      @room.leave "bob"
      @room.members.sort
    end.equals(%w(alice))

    context "and messages" do
      asserts("none yet") { @room.messages.size }.equals 0
      # TODO asserts("unknown user talks") { @room.say("unknown", "hi") }.raises(Chat::UserNotFound)
      asserts("bob talks") do
        @room.say("bob", "hi")
        @room.messages[-1].text
      end.equals("hi")

      asserts("alice talks") do
        @room.say("alice", "ho")
        @room.messages[-1].text
      end.equals("ho")

      asserts("have 2 messages") { @room.messages.map {|m| m.text } }.equals(%w(hi ho))

      asserts("clear messages") do
        @room.messages.clear
        @room.messages.size
      end.equals(0)
    end
  end

  context "messages" do
    setup do
      @messages = Chat::Messages.new(Chat::Database.new("messages"))
      @messages.clear
    end

    def message(text)
    end

    context "with empty" do
      asserts("zero sized") { @messages.size }.equals(0)
      asserts("empty ary") { @messages.to_a }.equals([])
      asserts("no first") { @messages[0] }.equals(nil)
      asserts("no range") { @messages[0, -1] }.equals([])
      asserts("no each") { @messages.each { |m| raise m }; 1 }.equals(1)
    end

    context "with messages" do
      setup do
        @messages << Chat::Message.new("bob", "hello", Time.now)
        @messages << Chat::Message.new("alice", "world", Time.now)
      end

      asserts("sized") { @messages.size }.equals(2)
      asserts("index 0") { @messages[0].text }.equals("hello")
      asserts("range 0") { @messages[0, 1].first.text }.equals("hello")
      asserts("index 1") { @messages[1].text }.equals("world")
      asserts("range 1") { @messages[1, 1].first.text }.equals("world")
      asserts("to_a") { @messages.to_a.map {|t| t.text} }.equals(%w(hello world))
      asserts("range all") { @messages[0, -1].map {|t| t.text } }.equals(%w(hello world))
      asserts("range out of bounds") { @messages[0, 23].map {|t| t.text } }.equals(%w(hello world))
      # TODO asserts("each works") { @messages.each {|m| raise m.text } }.raises("hello")
    end
  end

  context "message" do
    setup do
      @time = Time.now
      @message = Chat::Message.new("bob", "hello world", @time)
      @jsoned = JSON(JSON(@message))
    end

    asserts("has nickname") { @message.nickname }.equals("bob")
    asserts("has text") { @message.text }.equals("hello world")
    asserts("has created_at") { @message.created_at == @time }
    asserts("parses json nickname") { @jsoned.nickname == @message.nickname }
    asserts("parses json text") { @jsoned.text == @message.text }
    asserts("parses json created_at") { @jsoned.created_at.to_i == @message.created_at.to_i }
  end
end
