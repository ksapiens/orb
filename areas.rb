# ORB - Omnipercipient Resource Browser
# 
# 	Areas 
#
# copyright 2016 kilian reitmayr
require "helpers.rb"

class Area
	def index; $workspace.index self; end
	def root?; index == 2; end
	#def primary; @content.primary; end
	def update; end
	def << (object); @content << object; update;end
	#def [] (index); @content[index]; end
end
class Pager < Area 
	def initialize args 	
		@start = 0		
		super args
			#LOG.debug total.size 
	end
	#def total; @content; end
	def view show=height;	@content[@start..@start+show-1]; end		
	def paging?; @content.size > view.size ; end
	def pageup?; @start > 0; end
	def pagedown?; view[-1] != @content[-1]; end
	def page direction
		return unless ( direction == NEXT ? pagedown? : pageup? )
		@start += direction * (height - 2)
	end
	def draw 
		super do
			yield
			("^" * width).draw highlight: @focus, color: :text, 
				y: 0, area: self if pageup?
			("V" * width).draw highlight: @focus, color: :text, 
				y: height-1, area: self if pagedown?
		end
	end

	def primary x,y
		if y==height-1 && pagedown?
			page NEXT
		elsif y==0 && pageup?
			page PREVIOUS
		else
			return false#10#true
		end
	end
end

# List: manages + renders items
class List < Pager 
	def initialize args 
		super args 
		#@stack = []
		update
	end
	#def total; @stack + @content; end 
	def update #x=nil, y=nil 
		new_width = 0
		new_height = @content.length.max( lines - TOP - BOTTOM  )
		#if $workspace
		limit = ($workspace||[]).last == self ? 
			cols-left : LIMIT #@limit
		#else
		#	limit = LIMIT
		#end
		for entry in @content #total #view new_height
			if entry.width.between? new_width, limit 
				new_width = entry.width; end
		end
		resize new_height, new_width
		#move y, x if y && x
		refresh; end
	def draw
		super do
			for entry in view
				entry.draw self
				$/.draw area: self unless curx == 0 
			end
		end
	end
	def primary x=left,y=top
		x -= left; y -= top
		LOG.debug @content#view #result
		return if super x,y 

		return unless target = view[ y ]
	  $workspace = $workspace[0..index]
				
		#if id = STACK.content.index( target )	# @stack.include? targe
			
			#@stack = @stack[0..id]
			#target = @stack.pop
			#target.toggle
		#end

		result = target.primary
			#$workspace.last.primary 		
		
		if result[:down] && !result[:down].empty?
			#@limit = LIMIT
			#target.toggle
		 	if root?
				$workspace << ( List.new content: result[:down] )		 	
		 	else
		 		#STACK << target
		 		MENU << target
		 		#MENU.update
				@content = result[:down]
				@start = 0
				update
			end
		end
		if result[:right] && !result[:right].empty?
			$workspace << (( result[:right].is_a?(String) ? 
				Text : List).new content: result[:right] )
			update
		end		
	end
end

class Text < Pager
	def initialize args
		super args
		@content = @content.scan(
			/(.{0,#{width-1}})\s|$/).flatten.compact
#		@pagedown = @content.size > height
		
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

class Line < Area #Pager
	def initialize args
		@height = 1 unless @height
		super args
	end
	def draw	
		super do
			@prefix.draw area:self if @prefix
			for entry in @content #total
				entry.draw self
				@delimiter.draw	area:self if @delimiter
			end
		end
	end
	
end
