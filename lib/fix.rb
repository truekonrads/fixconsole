
module Fix
  CHECKSUM=10
  TIMESTAMP=52
  BODYLENGTH=9
  VERSION=8
  SOH="\1"
  MSGTYPE=35
  MSGSEQNUM=34
  HEADERTAGS=[35,49,56,34,142,52]
  class FixMessage
    def initialize(opts = {})
      @fixmsg = {8 => 'FIXT.1.1'}
      opts.each {|k,v|
        self.set_tag(k,v)
      }
    end

    def to_s ()
      #@fixmsg.map {|k,v| "#{k}=#{v}"}.join "|"
      to_fix().gsub SOH,'|'
    end

    def _fix_wo_checksum(msg=nil)
      if msg.nil?
        msg=@fixmsg
      end
      #FIXME: Order 8=1st, 9=2nd
      wo_specials=(msg.select {|k,v| not ([CHECKSUM,VERSION,BODYLENGTH].member? k)})
      s="8=#{@fixmsg[VERSION]}"+SOH
      s+="9=#{@fixmsg[BODYLENGTH]}"+SOH
      #Process "header" tags first
      HEADERTAGS.each {|t|
      	if wo_specials.member? t
      		#puts "[DD] - found tag #{t}" 
      		s+="#{t}=#{wo_specials[t]}"+SOH
      		#wo_specials.delete t
      	end
      }
      #Permit sending dupe tags

      wo_specials.map {|k,v| 
      	if v.is_a? Enumerable 
      		v.each {|vv|s+="#{k}=#{vv}"+SOH}	
      	elsif not HEADERTAGS.member? k	# we've already included those
	      		s+="#{k}=#{v}"+SOH
	      	
      	end
      }
      return s	
    end

    def to_fix (msg=nil)
      if msg.nil?
        msg=@fixmsg
      end

      s=self._fix_wo_checksum
      s+"10="+self.checksum(s)+SOH
    end

    def set_tag (tag,value)
      @fixmsg[tag.to_i]=value
    end

    def self.from_fix(fixstring)
      opts={}
      fixstring.split(SOH).each {|pair|
        k,v=pair.split '='
        opts[k.to_i]=v
      }
      self.new opts
    end

    def tags
      @fixmsg
    end

    def checksum (msg=nil)
      if msg.nil?
    	msg=self._fix_wo_checksum
      end
      sum=0
      msg.split("").each {|chr| sum+=chr.ord}
      "%03d" % (sum % 256)
    end

    def update_timestamp(time=nil)
      if time.nil?
        time=Time.now
      end
      timestring=time.strftime "%Y%m%d-%H:%M:%S.%L"
      @fixmsg[TIMESTAMP]=timestring
    end

    def update_checksum (sum=nil)
      if sum.nil?
        sum=self.checksum
      end

      @fixmsg[CHECKSUM]=sum
      sum
    end
    def receive_data(data)
    	puts data
    end
    def calc_length(msg=nil)
    	if msg.nil?
    		msg=@fixmsg
    	end
    	wo_specials=(msg.select {|k,v| not ([VERSION,BODYLENGTH,CHECKSUM].member? k)})
    	i=0
    	wo_specials.each {|k,v| i+=k.to_s.length+v.to_s.length+2}
    	return i
    end
    def update_length
    	self.set_tag(BODYLENGTH,self.calc_length)
    end
    def prepare_fix!
      self.update_timestamp
      self.update_length
      self.update_checksum
    end

  end

  class FixMessageFactory

    def initialize (opts)
      @opts=opts
    end

    def make (localopts={})
      args=@opts.merge localopts
      FixMessage.new args
    end
  end

  class HeartBeat < FixMessage

  end

end