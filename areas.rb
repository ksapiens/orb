
# ORB - Omnipercipient Resource Browser
# 
# 	Areas 
#
# copyright 2016 kilian reitmayr

# List: manages + renders items
class List < Area 
	def initialize args 
		super args 
		@stack = []
		@range = 0..bottom / SPACING - 3
		update
	end
	def total; (@stack + @entries)[@range];	end
	def update #x=nil, y=nil 
		height, width = ( total.length * SPACING ), 0
		for entry in total 
			if entry.width.between? width, @limit || cols
				width = entry.width; end
		end
		resize height.max( lines - TOP - BOTTOM - 1 ), width
		#move y, x if y && x
		refresh; end
	def << (object); @entries << object;	end
	def [] (index); @entries[index]; end
	def draw
		clear
		box '|', '-' if $DEBUG
		total.each_with_index do |entry, i|
			entry.draw 0,i*SPACING,self
#			entry.to_s.draw entry.color,i%2*10,0,i*SPACING,self		
		end
		refresh
		#LOG.debug "#{total}"
	end
	def primary x,y
		target = total[ (y - top) / SPACING ]
		content = target.primary @entries # TODO dont restore but click previous in stack
		if content[:right]
			WORKSPACE[(WORKSPACE.index self)+1..-1]=nil
			WORKSPACE[-1] = ( content[:right].is_a?(String) ? 
				Text : List).new( {
				entries: content[:right],
				x: right+1+MARGIN, y: TOP
			} ) 
		end
		if content[:down]
			if target.active
				@stack << target 
			else
				index = @stack.index target
				@stack = index == 0 ? [] : @stack[0..index-1]
			end
			@entries = content[:down]
			update
		end
	end
end
class Text < Area
	def draw
		clear
		box '|', '-' if $DEBUG
		@entries.draw :default,0,0,self
		refresh
	end
end
class Web < Area
	attr_reader :ip, :name, :services
	def initialize n 
		super 0, 0 , 0 , 0
		@name = n
	end
	def draw
		clear
		box '|', '-' if $DEBUG
		#text.draw 0, 0, :default, self
		refresh
	end
end	
