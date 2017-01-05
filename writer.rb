# ORB - Omnipercipient Resource Browser
# 
# 	Writer
#
# copyright 2016 kilian reitmayr
require "helpers.rb"

#class Area < Pad#Window
#
#	def initialize args 
#
#	end
#end

class Writer < Window #Pad #Area 
	attr_accessor :content, :delimiter, :page
	include Generic
	def initialize args 
		parse args  
		#LOG.debug "before %s %s %s %s" % [@y, @x, @height, @width]
		@x ||= ($world.last.right + MARGIN + 1)||LEFT
		@y ||= TOP
		@width ||= (cols-@x)
		@height ||= lines - TOP - BOTTOM - 1
		@delimiter ||= ""
		@page ||= 0
		@pages = [0]
		
		#LOG.debug "var %s %s %s %s" % [@y, @x, @height, @width]
		super @height, @width, @y, @x
		#LOG.debug @input.class				
		#@input = @input.read if @input.is_a? File
		case @input
			when String
				#fork do 
				@content = understand @input#, @log
				@text = true
				#@delimiter = ""
				#end
			when Command
				@content = @input.primary			
				@text = true
				#@input.entries.map{|line| Text.new line }
			when Enumerable
				@content = @input
				@delimiter = $/
		end
		work
	end
	def understand this#, log=false
		result = []
		if this.start_with? "__LOG" #log #@type == :log
			for lines in this.lines
				for line in lines.split "|"
					command = Command.new( line )
		#			LOG.debug command
					result << command.sequence.first if command.sequence
				end
			end
		else		
			begin
			#shapes = /(?<Host>(\w+:\/\/)?(\S+\.)*(\S+\.(?:gg|de|com|org|net))(\S+)*\s)|(?<Entry>\W(\/\w+)+)|(?<Host>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/
			shapes = /(?<Host>(\w+:\/\/)?(([\w\.-]+\.\w{2,3}\W)|(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}))([\w\/]+)*\s)|\W(?<Entry>(\/\w+)+)/
			#shapes = /((?<Protocol>\w+:\/\/)?(?<Subdomain>\w+\.)*(?<Domain>\w+\.(?:gg|de|com|org|net))[w\/\.]+)*\s)|()/
			match = shapes.match this
				if match 
#					LOG.debug match#.post_match
					text = match.pre_match
					item = match.to_h.select{|k,v| v}
#					LOG.debug item#match#.post_match
					result << eval( item.keys.first + #if item
						".new '#{item.values.first}'" )
				else					
					text = this #word )
					
				end
				result << text.lines.map{ |line| Text.new( line ) }
				#LOG.debug result#this[0..20]				
				#for word in rest.split
				#end
			end while match && this = match.post_match
			#@content.scan %r[(\w+\.(?:gg|de|com|org|net))] do |match|
			#%r[o].match @content do |match|
			
			#	result << Host.new( match.first )
			#end
		end
		result.flatten #@content = result 
	end
	def index; $world.index self; end
	def focus?; $focus == index; end
	def list?; @delimiter == $/; end
	def paging?; @content.size > @height ; end
	def pageup?; @page > 0 && paging?; end
	def pagedown?; @pagedown && paging?; end
	#def pagedown?; view[-1] != @content[-1]; end
	#def pagedown?; @start < @content[-1].y-@height; end
	#def oneline?; @height < 3; end
	def page direction
		#return unless
		#@start += direction * (height - 2)
		@page += direction if (direction==NEXT ? pagedown? : pageup?)
		#update
	end
	def add (item);	@content << item; end
	def << (object) 		
		#LOG.debug " << :#{object}"
		$world = $world[0..index] if index
		@content.unshift(object).flatten!
		@content.uniq! {|item| item.image.join "" }
		@file.write @content.to_yaml if @file
		#LOG.debug @file #bject.to_s
		#update
	end

	def view 
		if list? && paging? && !$filter.empty? && focus?
			return @content.reject{|i| !i.to_s.downcase.index(
				$filter) } 
			#[@start..@start+height-2]
		else
			#LOG.debug "#{@page} > #{@pages}"
			return @content[@pages[@page]..-1]
			#result = @content.select{|item|
				#item.y.between? @start, @start+height-2 }
		end		
	end		
	def add_page index
		(@pages << @pages.last + index ) if @page == @pages.size-1; 
	end
	def work
		clear 
		#setpos 0,0
		draw $/ if pageup?
		draw @prefix if @prefix
		#@pageup = false if view[0] == @content[0]
		view.each_with_index{ |item,i| #@content #
			#draw $/ if not list? && curx + item.width > width #&& item.width < width
			images = item.image list? #self, @selection				
			@pagedown = item != view.last #@content[-1] 
			#if images.join.length > 
			#if list? 
			#	if cury == height-1		
			#		add_page i
			#		break
			#	end
			#else
				available=(width - curx) + (height - cury - 2) * width
				rest = available - images.join.length
				#LOG.debug "#{item}.avail > #{available}"
				#LOG.debug "#{split}.rest > #{rest}"
				if rest < 0 or (cury == height-1 and curx == 0)
					#halt
					#images[0]=images.first[0..rest]
					#split = item.dup
					#split.skip = rest
					#@content.insert i, split
					add_page i 
					
					
					break
				#	item.wrap = rest
				end	
			#end
			draw @delimiter unless curx == 0 or not @delimiter
			item.x,item.y = curx,cury
			draw item.type.colored :dark unless @text
			#x,y = curx,cury
			for image in images
				#image=image[0..width-curx-1].colored(image.color)if list?
				draw image, selection:(@selection and focus?)				
			end
			#if curx == width && cury == height
			
			#break if cury == height-1
			#LOG.debug "item > #{item.inspect}"
		}
		if height > 2 #list?
			draw ("v" * width), y:height-1, highlight:focus? if 
				pagedown?
			draw ("^" * width), y:0, highlight:focus? if 
				pageup?
			draw (" " * width), highlight:focus?, y:height-1 unless 
				paging?
		end
		#box '|', '-' 
		refresh
	end
	def trim
		resize @height, LIMIT #unless self == $world.last
	end
	def action id=KEY_TAB, x=left,y=top
		x -= left; y -= top		
		if self == COMMAND
		LOG.debug "command :#{@content}"
			results = Command.new( @content.dup ).execute 
		elsif y==height-1 && pagedown?
			page NEXT
			return
		elsif y==0 && pageup?
			page PREVIOUS
			return
		else
			#results =  view[y].action
			#halt
#			LOG.debug "pointer :#{x}, #{y}" 
			previous = view.first
			for item in view[1..-1] #@content#
#				LOG.debug "previous :#{previous.x}, #{previous.y}" 
				#next unless previous #|| false
				results = previous.action( id ) if 
					( y == item.y and	item.y == previous.y and 
						x.between?(previous.x, item.x-1) ) or
					(y == previous.y and x >= previous.x ) or
					(y == item.y and x < item.x ) or 
					(y > previous.y and y < item.y )
#				LOG.debug "item :#{item.x}, #{item.y}" 
				previous = item
			end unless view.size == 1
			results = previous.action( id ) unless results
		end
#		LOG.debug "result :#{results}" 
		#target = @content[-1] unless target
		return unless results
		$world=$world[0..2]
		for result in results
			unless result.empty?		
#				LOG.debug "result: #{result}"#target #item				
				$world.last.trim #unless result.empty?		
				$world << Writer.new( 
					x:$world.last.right+MARGIN+1, 
					input: result, selection:true
					#delimiter:(result.is_a? String ? '':$/) 
					) 
			$focus=$focus.cycle NEXT, 2, $world.size-1
			end 
		end			
		
	end
end
