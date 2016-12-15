# ORB - Omnipercipient Resource Browser
# 
# 	Areas 
#
# copyright 2016 kilian reitmayr
require "helpers.rb"

class Area < Window
#	attr_accessor :content, :delimiter
	def index; $workspace.index self; end
	#def primary; @content.primary; end
#	def update; end
	#def [] (index); @content[index]; end
#	def initialize args 
#
	def initialize args 
		x = @x||($workspace.last.right + MARGIN + 1)
		
		#LOG.debug $workspace[-1] if $workspace
		super @height||lines-TOP-BOTTOM-1, @width||(cols-x), 
			@y||TOP, x
		
	end
#	end
end

class Writer < Area 
# List: manages + renders items
#class List < Pager 
	include Generic
			
	def initialize args 
		parse args  
		@delimiter ||= " "
		@start ||= 0
		super args
		#@content ||= @text.scan(
			#/(.{0,#{width-1}})\s|$/).flatten.compact
			#LOG.debug total.size 
	end
	
	def add (item)
		@content << item#.flatten
	end
	def << (object) 
		#LOG.debug object
		$workspace = $workspace[0..index] if index
		@content.unshift(object).flatten!
		@content.uniq! {|item| item.letters }
		@file.write @content.to_yaml if @file
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
		refresh
	end
	def view 
		if paging? && !$filter.empty?
			result = @content.reject{|i| 
				!i.to_s.downcase.index($filter) }
		else
			result = @content
		end		
		result#[@start..@start+height-1]; 
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
	#LOG.debug self
		
		clear 
		@prefix.draw area: self, color: :text if @prefix
		for item in view
			$/.draw area:self if curx + item.width > width #&& item.width < width
			
			@delimiter.draw area: self unless curx == 0 
			item.draw self 				
		end
		("^" * width).draw highlight: focus?, color: :text, 
			y: 0, area: self if pageup?
		("v" * width).draw highlight: focus?, color: :text, 
			y: height-1, area: self if pagedown?
		refresh
	end

	def primary x=left,y=top
	#	def primary x,y
		x -= left; y -= top
		if y==height-1 && pagedown?
			page NEXT
		elsif y==0 && pageup?
			page PREVIOUS
		else
			LOG.debug view#self.top#begy
			target = view[ y ]
			
			
			$stack << target unless 
				[Option, Section, Add].include? target.class
			
			return unless results = target.primary
			for result in results
		  #LOG.debug right
				$workspace.last.update unless result.empty?		
				$workspace << ( Writer.new x: $workspace.last.right+MARGIN, content: result, delimiter:$/ ) unless result.empty?		
			end			
		end
	end
end

#class TextArea < Pager
#	def initialize args
#		super args
		#

#		@pagedown = @content.size > height
		#@content = @content.lines
#	end
	
#	def primary x=left,y=top
#		x -= left; y -= top
#		super x,y
#	end
#end

#class Line < Area #Pager

#	def initialize args
#		@height ||= 1 
#		super args
#	end
	
#	def draw	
#		super do
#			@prefix.draw color: :text, area:self if @prefix
#			for entry in @content #total
#				entry.draw self
#				@delimiter.draw	area:self if @delimiter
#			end
#		end
#	end
#	def primary x=left,y=top
#		x -= left; y -= top
#		@content.first.primary self unless @content.empty?
#	end
#end
