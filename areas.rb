# ORB - Omnipercipient Resource Browser
# 
# 	Areas 
#
# copyright 2016 kilian reitmayr
require "helpers.rb"

class Area
	def index; $workspace.index self; end
	#def primary; @content.primary; end
	#def update; end
	#def [] (index); @content[index]; end
end
class Pager < Area 
	def initialize args 	
		@start = 0		
		super args
			#LOG.debug total.size 
	end
	#def total; @content; end
	def view 
		if paging? && !$filter.empty?
			result = @content.reject{|i| 
				!i.to_s.downcase.index($filter) }
		else
			result = @content
		end		
		result[@start..@start+height-1]; 
	end		
	def paging?; @content.size > height ; end
	def pageup?; @start > 0; end
	def pagedown?; view[-1] != @content[-1]; end
	def page direction
		return unless ( direction == NEXT ? pagedown? : pageup? )
		@start += direction * (height - 2)
	end
	def focus?; $focus == index; end
	def draw 
		super do
			yield
			("^" * width).draw highlight: focus?, color: :text, 
				y: 0, area: self if pageup?
			("V" * width).draw highlight: focus?, color: :text, 
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
		#LOG.debug self#height
		#update #unless $workspace||[]).last == self ? 
	end
	def << (object) 
		$workspace = $workspace[0..index]
		@content.unshift object
		@content.uniq!
		update
	end
	def update #x=nil, y=nil 
		new_width = 0
		for entry in @content #total #view new_height
			if entry.width > new_width
				new_width = entry.width.max LIMIT; end
		end
		resize height, new_width
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
		return if super x,y 
		target = view[ y ]
		return unless results = target.primary
		STACK << target unless [Option, Section].index target.class
		for result in results
			next if result.empty?#LOG.debug result			
			
			$workspace << (( result.is_a?(String) ? 
				TextArea : List).new content: result )
		end
		
		#$focus = -1
	end
end

class TextArea < Pager
	def initialize args
		super args
		#LOG.debug self		
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
	def primary x=left,y=top
		x -= left; y -= top
		super x,y
	end
end

class Line < Area #Pager
	attr_accessor :content
	def initialize args
		@height = 1 unless @height
		super args
	end
	def << (item)
		@content << item
		#@content.uniq!
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
	def primary x=left,y=top
		x -= left; y -= top
		@content.first.primary self
	end
end
