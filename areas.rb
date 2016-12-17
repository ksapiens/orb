# ORB - Omnipercipient Resource Browser
# 
# 	Areas 
#
# copyright 2016 kilian reitmayr
require "helpers.rb"

class Area < Window
	def index; $workspace.index self; end
	def initialize args 
		x = @x||($workspace.last.right + MARGIN + 1)||LEFT
		#
		super @height||lines-TOP-BOTTOM-1, @width||(cols-x), 
			@y||TOP, x
	end
#	end
end

class Writer < Area 
	attr_accessor :content, :delimiter
	include Generic
	def initialize args 
		parse args  
		@delimiter ||= ""
		@start ||= 0
		#LOG.debug @content
		if @content.is_a? String
			result = []
			@content.scan %r[(\w+\.(?:gg|de|com|org|net))] do |match|
			#%r[o].match @content do |match|
				LOG.debug match
				result << Host.new( match.first )
			end
			@content = result 
		end
		
		#@content ||= @text.split.map{|token| Text.new token }
		#scan(/(.{0,#{width-1}})\s|$/).flatten.compact 
		LOG.debug @content
			
		super args
		#update
		
	end
	def add (item)
		@content << item#.flatten
	end
	def << (object) 
		LOG.debug object
		#LOG.debug "area << :#{object}"
		$workspace = $workspace[0..index] if index
		@content.unshift(object).flatten!
		@content.uniq! {|item| item.letters }
		@file.write @content.to_yaml if @file
		update
	end
	def update #x=nil, y=nil 
		return unless @delimiter == $/
		new_width = 0
		#LOG.debug "area upd :#{content[-1]}"
		for entry in @content #total #view new_height
		
			if entry.width > new_width
				new_width = entry.width.max LIMIT; end
		end
		resize lines-4, new_width
		#move y, x if y && x
		refresh
		#LOG.debug "update  :#{top}"
	end
	def view 
		if paging? && !$filter.empty?
			result = @content.reject{|i| 
				!i.to_s.downcase.index($filter) }
		else
			result = @content
		end		
		return result unless @delimiter==$/ 
		result[@start..@start+height-1]
	end		
	def paging?; @content.size > height ; end
	def pageup?; @start > 0; end
	def pagedown?; view[-1] != @content[-1]; end
	def page direction
		return unless ( direction == NEXT ? pagedown? : pageup? )
		@start += direction * (height - 2)
	end
	def focus?; $focus == index; end
	def write
		clear 
		draw @prefix if @prefix
		for item in view
			#draw $/ if curx + item.width > width #&& item.width < width
			draw @delimiter unless curx == 0 
			for image in item.image #self, @selection				
				LOG.debug "draw > "+ image.to_s
				draw image, selection:@selection
			end
		end
		draw ("^" * width), highlight:focus?, y: 0 if 
			pageup? && height > 2
		draw ("v" * width), highlight: focus?,y: height-1 if 
			pagedown? && height > 2

		#box '|', '-' 
		refresh
	end

	def primary x=left,y=top
		x -= left; y -= top
		if y==height-1 && pagedown?
			page NEXT
		elsif y==0 && pageup?
			page PREVIOUS
		else
		
			target = view[ y ] 
			$stack << target unless 
				[Option, Section, Add].include? target.class
			return unless results = target.primary
			for result in results
		    LOG.debug "area results : #{result}"
				$workspace.last.update unless result.empty?		
				$workspace << Writer.new( 
					x:$workspace.last.right+MARGIN, 
					content: result, delimiter:$/, 
					selection:true ) unless result.empty?		
			end			
		end
	end
end
