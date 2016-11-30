
# ORB - Omnipercipient Resource Browser
# 
# 	Helpers
#
# copyright 2016 kilian reitmayr

module Generic
	def parse args
		for key, value in args
			instance_variable_set "@"+key.to_s, value
		end	if args.class == Hash		
	end
end

class String
	def file mode="r"; open self, mode; end
	def read; file.read; end
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
class Hash
	def method_missing *args
		self[args.first.to_sym] || super
	end
end
