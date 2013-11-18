CHECKSUM=10
TIMESTAMP=2
module Fix
	class FixMessage
		def initialize(opts = {})
			@fixmsg = {8 => 'FIXT.1.1'}
			opts.each {|k,v|
				self.set_tag(k,v)
			}
		#	@fixmsg=@fixmsg.merge opts
		#	self.update_timestamp
		end

		def to_s ()
			@fixmsg.map {|k,v| "#{k}=#{v}"}.join ";"
		end

		def to_fix (msg=nil)
			if msg.nil?
				msg=@fixmsg
			end
			(msg.map {|k,v| "#{k}=#{v}"}.join "\1")+ "\1"
		end

		def set_tag (tag,value)
			@fixmsg[tag.to_i]=value
		end

		def self.from_fix(fixstring)
			opts={}
			fixstring.split("\1").each {|pair|
				k,v=pair.split '='
				opts[k.to_i]=v
			}
			self.new opts
		end
		def tags
			@fixmsg
		end
		def checksum
			sum=0
			msg_wo_checksum=@fixmsg.select {|k,v| k!=CHECKSUM}
			self.to_fix(msg_wo_checksum).split("").each {|chr| sum+=chr.ord}
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
			
		end

		def prepare_fix
			self.update_timestamp
			self.update_checksum
			self.to_fix
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
