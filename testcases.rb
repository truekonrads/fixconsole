#!/usr/bin/env ruby
require 'eventmachine'
# Test cases
require 'date'
require_relative 'fixconsole'
require_relative 'lib/fix'
require 'ronin'
include Fix

# login_with_dupes=FixMessage.new LOGIN.merge DEFAULTS
# login_with_dupes.set_tag 49,["GSED018437" , "GSED028437"]

# sess=FixSession.new :login_message => login_with_dupes
# sess.go

# cb=Proc.new {|sess|

#   	EM::Timer.new(10) do
#     puts "[DDDDDDDDDDDDDDD]Ring! Ring! Ring"
#     login_with_pwd=FixMessage.new LOGIN.merge DEFAULTS
#     login_with_pwd.set_tag 49,["GSED028437","GSED018437"]
#     login_with_pwd.set_tag 553,"FIXB"
#     login_with_pwd.set_tag 554,"test123"
#     sess.send_fix login_with_pwd
# 	end

# }
# sess=FixSession.new :on_showtime => cb


class FuzzingLoginSession <FixSession
  def initialize(*args)
    @vectors=nil#Ronin::Fuzzing[:format_strings]
    @fuzztags=[142]#553, 554, 1137, 1407]
    @tagindex=0
    super
    @ranonce=false
    @msgcounter=0
  end
  def init_states
  	super
    @state.on(:showtime) do
      puts "[DD] How did we get through? closing connection"
      @connection.close_connection
    end
  end
  def send_fix (*args)
    @msgcounter+=1
    puts "[D] Message #{@msgcounter} sent on #{Time.now.to_s}"
    super
  end
  def send_login
    tagsoup={
      8 => "FIXT.1.1",
      9 => "121",
      35 => "A",
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
      142 => "TRFXMAB1234567890",
      49 => "GSED028437",
      553 => "FIXA",
      554 => "test123",
      56 => "TR MATCHING",
      #141 => "Y"
    }
    login=Fix::FixMessage.new tagsoup
    #Fuzz here!
    if @ranonce
    	
      begin
        if @tagindex < 	@fuzztags.length          
          tag=@fuzztags[@tagindex]
          if @vectors.nil?
          	puts "Defining vectors"
          	@vectors=(Ronin::Fuzzing::Mutator.new /./ => ["\0"]).each(tagsoup[tag])
          	puts "Defined"
		  end          
          v=@vectors.next
          puts "[DD] Fuzzing tag #{tag} with vector #{v}"
          login.set_tag tag, v
        else

          puts "[!!] Done!"
          EM.stop
          exit!
        end
      rescue StopIteration => e
        @tagindex+=1
        @vectors=nil
        puts "[DD] Incrementing @tagindex to #{@tagindex} "
        
      end
    end
    @config[:login_message]=login
    @ranonce=true
    super
  end
end
sess=FuzzingLoginSession.new :reconnect_sleep =>nil
sess.go