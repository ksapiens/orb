# ORB - Omnipercipient Resource Browser
# 
# 	Areas 
#
# copyright 2016 kilian reitmayr
require "helpers.rb"

class Pager < Area 
	
	def initialize args 	
		@start = 0		
		super args
			#LOG.debug total.size 
	end
	def total; @content; end
	def view show=height; total[@start..@start+show-1]; end
	def paging?; total.size > view.size ; end
	def pageup?; @start > 0; end
	def pagedown?; view[-1] != total[-1]; end
	def page direction
		return unless ( direction == NEXT ? pagedown? : pageup? )
		@start += direction * (height - 2)
	end
	
	def draw 
		super do
			yield
			("^" * width).draw \
				highlight: @focus, color: :text, y: 0, area: self if pageup?
			("V" * width).draw \
				highlight: @focus, color: :text, y: height-1, area: self if pagedown?
		end
	end

	def primary x,y
		if y==height-1 && pagedown?
			page 1
		elsif y==0 && pageup?
			page -1
		else
			return false#10#true
		end
	end
end

# List: manages + renders items
class List < Pager 
	def initialize args 
		super args 
		@stack,@original = [], @content
		update
	end
	def total; @stack + @content; end 
	def update #x=nil, y=nil 
		new_width = 0
		new_height = total.length.max( lines - TOP - BOTTOM )
		for entry in view new_height
			if entry.width.between? new_width, @limit || cols-left
				new_width = entry.width; end
		end
		resize new_height, new_width
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
	def primary x,y
		x -= left; y -= top
		return if super x,y 
		
		return unless target = view[ y ]
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
			@limit = LIMIT
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

class Text < Pager
	def initialize args
		super args
		@content = @content.scan(
			/(.{0,#{width-1}})\s|$/).flatten.compact
		@pagedown = @content.size > height
		
		#@content = @content.lines
	end
	def draw
		#LOG.debug view #@content
		super do
			for line in view #@content[@start..height]
				(line + $/).draw color: :text, area: self
			end
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
	#def paginate?; false; end	
	def to_s
		@input.map(&:name).join(" ")
	end
	def total; [ @to_s ]; end
	def draw
		super do
			@prompt.draw({ color: :prompt, area: self })
		  to_s.draw({ color: :command, area: self }) 
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
