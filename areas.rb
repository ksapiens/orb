# ORB - Omnipercipient Resource Browser
# 
# 	Areas 
#
# copyright 2016 kilian reitmayr
require "helpers.rb"

#class Area < Pad#Window
#
#	def initialize args 
#
#	end
#end

class Writer < Pad #Area 
	attr_accessor :content, :delimiter
	include Generic
	def initialize args 
		parse args  
		
		@x ||= ($world.last.right + MARGIN + 1)||LEFT
		@y ||= TOP
		@width ||= (cols-@x)
		@height ||= lines - TOP - BOTTOM
		@delimiter ||= ""
		@start ||= 0
		super 10000, @width
		
		#LOG.debug @input.class				
		@input = @input.read if @input.is_a? File
		case @input
			when String
				#fork do 
				@content = understand @input#, @log
				#end
			when Command
				@content = @input.primary			
				#@input.entries.map{|line| Text.new line }
			when Enumerable
				@content = @input
				#@delimiter = $/
		end
		#@content ||= @text.split.map{|token| Text.new token }
		#scan(/(.{0,#{width-1}})\s|$/).flatten.compact 
		#update
		
		work
		#addstr "test"
		#refresh 0,0, @y, @x, @height, @width
		update
		LOG.debug "pad %s %s %s %s" % [top, left, height, width]
		LOG.debug "var %s %s %s %s" % [@y, @x, @height, @width]

	end
	def understand this#, log=false
		result = []
		if this.start_with? "#LOG" #log #@type == :log
			for lines in this.lines
				for line in lines.split "|"
		#			LOG.debug line
					command = Command.new( line )
		#			LOG.debug command
					#@content << command.sequence.first if command.sequence
					result << command.sequence.first if command.sequence
					# << Command.new( line )
				end
			end
			
			#@content.compact! 
		else		
			#result = []
			begin
				
			#match=/(?<Host>\w+\.(?:rb|gg|de|com|org|net))/.match this
			match=/(?<Host>(\w+:\/\/)?(\w+\.)?(\w+\.(?:gg|de|com|org|net))([w\/\.]+)?)\s/.match this
				#LOG.debug match.post_match
				
				if match 
					result << Text.new( match.pre_match )#word )				
					item = match.to_h.select{|k,v| v}
					result << eval( item.keys.first + #if item
						".new '#{item.values.first}'" )
				else					
					result << Text.new( this )#word )
					LOG.debug this#[0..20]				
				end
				#for word in rest.split
				#end
			end while match && this = match.post_match
			#@content.scan %r[(\w+\.(?:gg|de|com|org|net))] do |match|
			#%r[o].match @content do |match|
			
			#	result << Host.new( match.first )
			#end
		end
		result #@content = result 
	end
	def index; $world.index self; end
	def focus?; $focus == index; end
	def list?; @delimiter == $/; end
	def paging?; @content.size > @height ; end
	def pageup?; @start > 0; end
	#def pagedown?; view[-1] != @content[-1]; end
	def pagedown?; @height > 2; end
	def page direction
		return unless ( direction == NEXT ? pagedown? : pageup? )
		@start += direction * (height - 2)
		refresh @start,0, top,left,height,width
	end

	def add (item);	@content << item; end
	def << (object) 		
		#LOG.debug "area << :#{object}"
		$world = $world[0..index] if index
		@content.unshift(object).flatten!
		@content.uniq! {|item| item.image.join "" }
		@file.write @content.to_yaml if @file
		#LOG.debug @file #bject.to_s
		update
	end
	def update x=nil, y=nil 
		#return unless list?
		#resize lines - TOP - BOTTOM, new_width.max( LIMIT )
		refresh @start, 0, @y, @x, @height, @width
		#refresh y||0, x||0, top, left, bottom, right
		#LOG.debug "update  :#{top}"
	end
#	def view 
		#if paging? && !$filter.empty? && list? && focus?
		#	result = @content.reject{|i| 
		#		!i.to_s.downcase.index($filter) }
		#else
#		return @content if @start == 0
#			result = @content.select{|item|
#				item.y.between? @start, @start+height-2 }
		#end		
		#return result unless list? #@delimiter==$/  
		#result = [@start..@start+height-2]
#	end		
	
	def work
		clear 
		draw @prefix if @prefix
		for item in @content #view
			#item.x,item.y = curx,cury
			
			LOG.debug "draw > #{item.to_s}"
			#draw $/ if not list? && curx + item.width > width #&& item.width < width
			draw @delimiter unless curx == 0 
			for image in item.image list? #self, @selection				
				image=image[0..width-curx-1].colored(image.color)if list?
				draw image, selection:(@selection && focus?)
				
			end
			#break if curx == width && cury == height
		end
		if height > 2
			draw ("^" * width), highlight:focus?, y:0 if 
				pageup? 
			draw ("v" * width), highlight:focus?, y:@height-1 if 
				pagedown?
			draw (" " * width), highlight:focus?, y:@height-1 unless 
				paging?
		end
		#box '|', '-' 
		#refresh
		#@width = 0
		#LOG.debug "area upd :#{content[-1]}"
		#for entry in @content #total #view new_height
		#	if entry.width > @width
		#		@width = entry.width; end
		#end
		update
	end
	
	def primary x=left,y=top
		#if 
			#cmd = 
			#@content.first.history << cmd
			#$world
			#system "%s %s &" % [TERM, @content.join(" ")] 
		#end
		x -= left; y -= top		
		if y==height-1 && pagedown?
			page NEXT
		elsif y==0 && pageup?
			page PREVIOUS
		else
		  if self == COMMAND
				target = Command.new( content.dup )
			#else
			#	for item in view
			#		target = item if x > item.x && y > item.y
			#	end
			end
			$stack << target unless 
				[Option, Section, Add].include? target.class
			return unless results = target.primary
			for result in results
		  #LOG.debug "command : #{result}"  
				$world.last.update unless result.empty?		
				
				$world << Writer.new( 
					x:$world.last.right+MARGIN, 
					input: result, #delimiter:$/, 
					selection:true ) unless result.empty?		
				$focus=$focus.cycle NEXT, 2, $world.size-1
			end			
		end
	end
end
