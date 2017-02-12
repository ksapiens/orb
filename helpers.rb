
# ORB - Omnipercipient Resource Browser
# 
# 	Helpers
#
# copyright 2016 kilian reitmayr
require 'fileutils'
require 'shellwords'
require 'pry'

def halt
#	close_screen
	binding.pry 
end

module Generic
#class Hash
	def variables_from args#bind#, local = false
		args.each{ |name, value| 
			instance_variable_set "@"+name.to_s, value }
#		for 
#			
			#bind.
			#local_variable_set key.to_s, value
#		end	#if args.class == Hash	
	end
end

class String
#	attr_accessor :color
#	def initialize string, color
#		super string
#		@color = color
#	end
	
	{ FileUtils: %w[ cd mkdir touch rm ],
		FileTest: %w[ exists? directory? executable? ] 
	}.each{ |klass, methods| 
		for method in methods
			eval "def #{method}; #{klass}.#{method} path; end"
		end }	
	
	def colored color;s=dup;s.color=color;s; end
 	#"\e[#{30+n}m#{self}\e[0m"
 	
	def file mode="r"; open path, mode; end
	def read cap=nil; cap ? file.read( cap ) : file.read; rescue; end
	def write content; f=file("w");f.write content;f.close; end
	def copy target; FileUtils.copy path, target.path; end
	def path; gsub(/^~\//, ENV["HOME"]+"/").gsub(/^\.\//,ENV["PWD"]+ "/"); end	
	def item; Item.new self;end
	def entry
		return if self[/cannot open/] or 
			self[/no read permission/] or self.empty?
		#LOG.debug self
		if types = /:\s*([\w-]+)\/([\w-]+)/.match(self)
    	type=((%w{directory text audio video image symlink socket chardevice fifo} & 
    		types[1..2]) + ["entry"] ).first
			path = self[/^.*:/][0..-2]    
    	type = "executable" if !%w{directory symlink}.include?(type) && path.executable?
    	#type = "config" 
    	type += "file" if type == "text" 
    	(eval type.capitalize).new long:Shellwords.escape(path), short: :name
    end
  end
  
  def parse raw=true
  	result = []
  	#shapes = /(?<Host>(\w+:\/\/)?(\S+\.)*(\S+\.(?:gg|de|com|org|net))(\S+)*\s)|(?<Entry>\W(\/\w+)+)|(?<Host>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/
		#shapes = /((?<Protocol>\w+:\/\/)?(?<Subdomain>\w+\.)*(?<Domain>\w+\.(?:gg|de|com|org|net))[w\/\.]+)*\s)|()/
		
#		shapes = /(?<Host>(\w+:\/\/)?([\w\.-]+\.(?:gg|de|com|org|net))|(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})([\w\/]+)*\s)?|\W(?<Entry>(\/\w+)+)/
		#shapes = /(((http|ftp|https):\/{2})+(([0-9a-z_-]+\.)+(aero|asia|biz|cat|com|coop|edu|gov|info|int|jobs|mil|mobi|museum|name|net|org|pro|tel|travel|ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cu|cv|cx|cy|cz|cz|de|dj|dk|dm|do|dz|ec|ee|eg|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gg|gh|gi|gl|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|je|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|me|mg|mh|mk|ml|mn|mn|mo|mp|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz|nom|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ra|rs|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|sj|sk|sl|sm|sn|so|sr|st|su|sv|sy|sz|tc|td|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|yu|za|zm|zw|arpa)(:[0-9]+)?((\/([~0-9a-zA-Z\#\+\%@\.\/_-]+))?(\?[0-9a-zA-Z\+\%@\/&\[\];=_-]+)?)?))\b/imuS
		#shapes = /@^(https?|ftp)://[^\s/$.?#].[^\s]*$@iS/
		this = self
		begin
			shapes = %r[\W(?<Option>--?\w[\w-]+)\W|\W(?<Entry>\/[^:\s]+)\W]
			match = shapes.match this
			if match 
				#LOG.debug match#.post_match
				#before = match.pre_match#.strip
				#result << Text.new( long:before ) if 
				#	raw and not before.empty? 
				type, string = *match.to_h.select{|k,v|v}.first
				result << Text.new( long:this[0..match.begin(type)-1] )
				
				#if type == "Entry" 
					#result << ( `file -i #{string}`.entry or 
				#	result << Entry.new(long:string) #)
				#else
					result << (eval type).new( long: string )#Shellwords.escape(
						#string) ) 
				#end 
				this = this[match.end(type)..-1]
			else					
				result << Text.new( long:this) if raw and not this.empty? 
			end
		end while match
		result.flatten 
	end
end
		
class Fixnum
	def cycle direction, min, max
		return self unless direction
		(min if self>max) or (max if self<min) or (self+direction)
	end
	def min i; return i if self < i if i; self; end
	def max i; return i if self > i if i; self; end
end

class MatchData
	def to_h; Hash[ names.zip captures ];	end
end

class Array
	def longest
		max = first
		each{|entry| max = entry if entry.length > max.length }
		max
	end
end
