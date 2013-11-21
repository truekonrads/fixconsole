#!/usr/bin/env ruby
require 'rubygems'
require 'eventmachine'
require 'micromachine'
require 'date'
require_relative 'lib/fix.rb'
LOGIN={
  8 => "FIXT.1.1",
  9 => "121",
  35 => "A",
  56 => "YOURTARGETCOMPID",
  34 => "1",
  142 => "YOURCOMPLOCATION",
  52 => "20131118-14:48:16",
  98 => "0",
  108 => "4",
  789 => "1",
  1137 => "9",
  1407 => "100",
  10 => "034",
  142 => "YOURTARGETCOMPID",
  553 => "FIXUser",
  554 => "lalalala",
  #141 => "Y"

}

HEARTBEAT = {
  8 => "FIXT.1.1",
  35 => "0"
}

DEFAULTS={
  49 => "SENDERCOMPID",
  56 => "YOURTARGETCOMPID",

}
class FixConnection < EM::Connection
  def initialize(fixsession)
    super
    @fixsession=fixsession
    fixsession.set_connection self
  end

  def send_fix(fixmsg)
    send_data(fixmsg.to_fix)
  end

  def receive_data(data)
    fix=Fix::FixMessage.from_fix data
    puts fix
    @fixsession.message_received fix

  end

  def unbind
    #puts "Connection closed"
    @fixsession.unbind
    #EM.stop
  end

  def post_init
    puts "[D] EM/Connected"
    @fixsession.connection_ready self
  end
end

class FixSession
  def initialize (opts={})
    defaults = {
      :auto_logon => true,
      :login_message => nil,
      :on_showtime => nil,
      :reconnect_sleep => 3
      }
    @config=defaults.merge opts
    @state=MicroMachine.new(:new)
    @connection=nil
    @msgSeqNum=0
    @fixmsg=nil
    @heartbeatint=nil
    @hbtimer=nil
    @nextSeqNumber=1
    init_states
    @connection=nil
  end
  def set_connection (c)
    @connection=c
  end
  def init_states
    @state.when(:connection_ready,:new => :connected)
    @state.on(:connected) do
      if @config[:auto_logon]
        send_login
      end
    end
    @state.when(:logon_succeeded,:connected => :showtime)
    @state.when(:logon_error,:connected => :failed_login)


    @state.when(:unbind,:connected => :new, :showtime => :new)

    @state.on(:new) do
      if not @hbtimer.nil?
        @hbtimer.cancel
      end
    end
    @state.on(:showtime) do
      puts "[D] Showtime!"
      if not @config[:on_showtime].nil?
        @config[:on_showtime].call self
      end
      # start_heartbeat @heartbeatint
    end

  end

  def send_fix (fix)
    #    puts "[D] My state is #{@state.state}"
    if @state.state==:showtime
      self.cancel_heartbeat
    end
    DEFAULTS.each {|k,v|
      if not fix.tags.member? k
        fix.set_tag(k,v)
      end
    }
    @msgSeqNum+=1
    fix.set_tag Fix::MSGSEQNUM,@msgSeqNum
    fix.prepare_fix!
    #puts fix
    #puts "[D] Using #{@msgSeqNum} for MsgSeqNum"
    @connection.send_fix fix
    if @state.state==:showtime
      self.start_heartbeat
    end

  end

  def send_login
    if @config[:login_message]
      login=@config[:login_message]
    else
      login=Fix::FixMessage.new LOGIN
    end
    login.set_tag Fix::MSGSEQNUM,@msgSeqNum
    #login.set_tag 52,"121"
    login.set_tag 789,@nextSeqNumber
    send_fix login
  end
  def connection_ready (connection)
    @connection=connection
    @state.trigger(:connection_ready)
  end

  def unbind
    @connection=nil
    puts "[D] Connection lost"
    @state.trigger(:unbind)
    if not @config[:reconnect_sleep].nil? 
      sleep @config[:reconnect_sleep]
    end
    self.go
  end

  def cancel_heartbeat
    if not @hbtimer.nil?
      @hbtimer.cancel
    end
  end

  def start_heartbeat
    me=self
    @hbtimer=EM::Timer.new (@heartbeatint) do
      me.do_heartbeat
    end
  end
  def do_heartbeat (testreqid=nil)
    #puts "[D] doing heartbeat, testreqid=#{testreqid}"
    if @state.state==:showtime
      hb=Fix::FixMessage.new HEARTBEAT
      if not testreqid.nil?
        hb.set_tag 112, testreqid
      end
      self.send_fix hb
    end
  end

  def message_received (fix)
    @nextSeqNumber+=1
    #puts "[D] I am message_received and the state is #{@state.state}"
    @fixmsg=fix
    if @state.state==:connected or @state.state==:showtime
      if fix.tags[35]=="5"
      if (match=/Tag 34 \(MsgSeqNum\) is lower than expected. Expected (\d+)/.match(fix.tags[58]))
        msgSeqNum=match.captures[0]
        puts "[D] Got complaint about bad message number, "
        @msgSeqNum=(msgSeqNum.to_i)
        puts "[D] The new MsgSeqNum is #{@msgSeqNum}"
      else
        puts "[D] We got booted off: #{fix.tags[58]}"
      end

    end
      if fix.tags[35]=="A"  # LOGON
        @msgSeqNum=(fix.tags[789].to_i-1)
        @heartbeatint=fix.tags[108].to_i
        @state.trigger(:logon_succeeded)
      end
      if fix.tags[35]=="4" # SequenceReset
        print "[D] Got a SequenceReset message. New MsgSeqNum should be #{fix.tags[36]}"
        @nextSeqNumber=fix.tags[36].to_i
      end

      if fix.tags[35]=="1" # TestRequest
        print "[D] Got a TestRequest message with TestRequestId #{fix.tags[112]}"
        self.do_heartbeat fix.tags[112]
      end
    end
  end

  def go
    EM.run {
      puts "[D] About to execute EM.connect"
      EM.connect('192.168.61.1', 2043, FixConnection,self)
    }
  end
end
if __FILE__ == $0
  FixSession.new.go
end
