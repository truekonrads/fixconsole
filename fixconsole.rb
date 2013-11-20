#!/usr/bin/env ruby
require 'rubygems'
require 'eventmachine'
require 'micromachine'
require_relative 'lib/fix.rb'
LOGIN={
  8 => "FIXT.1.1",
  9 => "121",
  35 => "A",
  49 => "GSED01 8437",
  56 => "TR MATCHING",
  34 => "1",
  142 => "TRFXMAB1234567890",
  52 => "20131118-14:48:16",
  98 => "0",
  108 => "4",
  789 => "1",
  1137 => "9",
  1407 => "100",
  10 => "034",
  142 => "TRFXMAB1234567890"
  #141 => "Y"
}

HEARTBEAT = {
  8 => "FIXT.1.1",
  35 => "0"
}

DEFAULTS={
  49 => "GSED018437",
  56 => "TR MATCHING",
  
}

class FixConnection < EM::Connection
  def initialize(fixsession)
    super
    @fixsession=fixsession
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
  def initialize
    @state=MicroMachine.new(:new)
    @connection=nil
    @msgSeqNum=0
    @fixmsg=nil
    @heartbeatint=nil
    init_states
  end
  def init_states
    @state.when(:connection_ready,:new => :connected)
    @state.on(:connected) do
      send_login
    end
    @state.when(:logon_succeeded,:connected => :showtime)
    @state.when(:logon_error,:connected => :failed_login)
    

    @state.when(:unbind,:connected => :new, :showtime => :new)
    

    @state.on(:showtime) do 
      start_heartbeat
    end
    
  end

  def send_fix (fix)
    puts "[D] My state is #{@state.state}"
    DEFAULTS.each {|k,v|
      fix.set_tag(k,v)
    }
    @msgSeqNum+=1
    fix.set_tag Fix::MSGSEQNUM,@msgSeqNum
    fix.prepare_fix!
    puts fix
    puts "[D] Using #{@msgSeqNum} for MsgSeqNum"
    @connection.send_fix fix
  end

  def send_login
    login=Fix::FixMessage.new LOGIN
    login.set_tag Fix::MSGSEQNUM,@msgSeqNum
    #login.set_tag 52,"121"
    send_fix login
  end
  def connection_ready (connection)
    @connection=connection
    @state.trigger(:connection_ready)
  end

  def unbind
    @connection=nil
    puts "[D] Connection lost, state #{@state.state}"
    @state.trigger(:unbind)
    puts "[D] New  state #{@state.state}"
    #@state.state=:new
    sleep 3
    self.go
  end
  def start_heartbeat (hbint)
    @heartbeatint=hbint/2
    me=self
    EM::Timer.new (@heartbeatint) do 
      me.method(:do_heartbeat)
    end
  end
  def do_hearbeat
    if @state.state==:showtime
      hb=Fix::FixMessage HEARTBEAT
      self.send_fix hb
    end
  end
  def message_received (fix)
    puts "[D] I am message_received and the state is #{@state.state}"
    @fixmsg=fix
    if @state.state==:connected or @state.state==:showtime
      if fix.tags[35]=="5" and (msgSeqNum=/Tag 34 \(MsgSeqNum\) is lower than expected. Expected (\d+)/.match(fix.tags[58]).captures[0])
        puts "[D] Got complaint about bad message number, "
        @msgSeqNum=(msgSeqNum.to_i)
        puts "[D] The new MsgSeqNum is #{@msgSeqNum}"
      end
      if fix.tags[35]=="A"
        @msgSeqNum=(@msgSeqNum.to_i-1)
        @heartbeatint=fix.tags[108].to_i
        @state.trigger(:logon_succeeded)                
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
  #runme!
  FixSession.new.go