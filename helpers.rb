
# ORB - Omnipercipient Resource Browser
# 
# 	Helpers
#
# copyright 2016 kilian reitmayr
require 'fileutils'
require 'shellwords'

module Generic
	def parse args, local = false
		for key, value in args
			instance_variable_set "@" + key.to_s, value
			#local_variable_set key.to_s, value
		end	if args.class == Hash	
	end
		
end

class String
	attr_accessor :color
#	def initialize string, color
#		super string
#		@color = color
#	end
	
	{ FileUtils: %w[ cd mkdir touch ],
		FileTest: %w[ exists? directory? executable? ] 
	}.each{ |klass, methods| 
		for method in methods
			eval "def #{method}; #{klass}.#{method} path; end"
		end }	
	
	def colored color;s=dup;s.color=color;s; end
 	#"\e[#{30+n}m#{self}\e[0m"
 	
	def file mode="r"; open path, mode; end
	def read; file.read; end
	def write content; f=file("w");f.write content;f.close; end
	def copy target; FileUtils.copy path, target.path; end
	def path; gsub "~", ENV["HOME"]; end	
	def item; Item.new self;end
	def entry
		return if self[/cannot open/] || 
			self[/no read permission/] || self.empty?
		#LOG.debug self
		if types = /:\s*([\w-]+)\/([\w-]+)/.match(self)
    	type=((%w{directory text audio video image symlink socket chardevice fifo} & 
    		types[1..2]) + ["entry"] ).first
			path = self[/^.*:/][0..-2]    
    	type = "executable" if !%w{directory symlink}.include?(type) && path.executable?
    	#type = "config" 
    	type += "file" if type == "text" 
    	(eval type.capitalize).new Shellwords.escape path
    end
  end
end

#class String
#	def [] args
#		super[args].colored @color
#	end
#end
		
class Fixnum
	def cycle direction, min, max
		#return if $world.select(&:paging?).empty? #each_with_index.map{|area,index| 
		#if area.paging? && index != self }.compact[self+direction]
		copy = self + direction
		copy = min if copy > max
		copy = max if copy < min
		copy
		#cycle direction unless $world[copy].paging?
	end
#		return min if copy < min
#		return max if copy > max; 
#		copy end; 
	def min i
		return i if self < i if i
		self; end
	def max i	
		return i if self > i if i
		self; end
end

class MatchData
	def to_h; Hash[ names.zip captures ];	end
end

class Hash
#	def method_missing *args
#		self[args.first.to_sym] || super
#	end
end

