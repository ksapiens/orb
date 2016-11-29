# ORB - Omnipercipient Resource Browser
# 
# 	Areas 
#
# copyright 2016 kilian reitmayr

# List: manages + renders items
class List < Area 
	def initialize args 
		super args 
		@stack,@start,@original = [], 0, @content
		#@pagedown = @content.size > height
		update
	end
	def total; @stack + @content; end 
	def view show=height; total[@start..@start+show]; end
	def update #x=nil, y=nil 
		#height, width = view.length, 0
		new_width = 0
		new_height = total.length.max( lines - TOP - BOTTOM )
		
		for entry in view new_height
			if entry.width.between? new_width, @limit || cols-left
				new_width = entry.width; end
		end
		resize new_height, new_width
		LOG.debug total.size 
		LOG.debug height 
		LOG.debug view.size 
		@pagedown = total.size > height
		#move y, x if y && x
		refresh; end
	def << (object); @content << object;	end
	def [] (index); @content[index]; end
	def draw
		super do
			for entry in view
				entry.draw self
			end
		end
	end
	def page direction
		if direction == :down
		
			@start += height - 2
			@pagedown = view[-1] != total[-1]
			@pageup = true
		elsif direction == :up
			@start -= height - 2
			@pageup = view[0] != total[0]
			@pagedown = true
		end
	end
	def primary x,y
		x -= left; y -= top
		return if super x,y 
		#LOG.debug testa
		target = view[ y ]
		if @stack.include? target
			index = @stack.index target
			if index == 0
				@stack = []
				target.toggle 
				@content = @original
				WORKSPACE.pop
				update
				return
			else 
				@stack = @stack[0..index-1]
				target = @stack.pop
				target.toggle
			end
		end
		result = target.primary 
		#LOG.debug result
		if result[:down]
			target.toggle
		 	@stack << target
			@content = result[:down]
			@start,@pageup = 0,false
			update
		end
		if result[:right]
			WORKSPACE[(WORKSPACE.index self)+1..-1]=nil
			WORKSPACE[-1] = ( result[:right].is_a?(String) ? 
				Text : List).new( {
				content: result[:right],
				x: right+1+MARGIN, y: TOP, 
				height: lines - TOP - BOTTOM - 1#, limit: LIMIT
			} ) 
		end		
	end
end
class Text < Area
	def initialize args
		super args
		@pagedown = true
		@pageup = true
	end
	def draw
		super do
			@content.draw :text,self
		end
	end
	def primary x,y
		x -= left; y -= top
		super x,y
	end
end


class Command < Area
	attr_accessor :prompt, :input
	#def initialize args
	#	super args
	#end
	def to_s
		@input.map(&:name).join(" ")
	end
	def draw
		super do
			@prompt.draw :prompt,self
		  to_s.draw :command,self
		end
	end
	def primary x=nil,y=nil
		LOG.debug "%s %s" % [TERM, to_s]
		system "%s %s" % [TERM, to_s]
	end
	
end

class Web < Area
	attr_reader :ip, :name, :services
	def initialize n 
		super 0, 0 , 0 , 0
		@name = n
	end
	
end	
