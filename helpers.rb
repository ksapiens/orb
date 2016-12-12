
# ORB - Omnipercipient Resource Browser
# 
# 	Helpers
#
# copyright 2016 kilian reitmayr
require 'fileutils'

module Generic
	def parse args, local = false
		for key, value in args
			instance_variable_set "@" + key.to_s, value
			#local_variable_set key.to_s, value
		end	if args.class == Hash	
	end
		
end
class String
	{ FileUtils: %w[ cd mkdir touch ],
		FileTest: %w[ exists? directory? executable? ] 
	}.each{ |klass, methods| 
		for method in methods
			eval("def %s; %s.%s path; end" % [method,klass,method])
		end
	}	
	def file mode="r"; open path, mode; end
	def read; file.read; end
	def write content; f=file("w");f.write content;f.close; end
	def copy target; FileUtils.copy path, target.path; end
	def path; gsub "~", ENV["HOME"]; end
end

class Fixnum
#	def limit min, max
#		return min if self < min
#		return max if self > max; 
#		self end; 
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
