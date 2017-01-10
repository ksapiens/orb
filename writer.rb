# ORB - Omnipercipient Resource Browser
# 
# 	Writer
#
# copyright 2016 kilian reitmayr
require "helpers.rb"

class Writer < Pad #Window #
	attr_accessor :content, :page
	#attr_reader :delimiter
	include Generic
	def initialize args 
		parse args  
		
		@x ||= ($world.last.right + MARGIN + 1) or LEFT
		@y ||= TOP
		@width ||= (cols-@x)
		@height ||= lines - TOP - BOTTOM - 2
		@delimiter ||= $/
		@page ||= 0
		LOG.debug "writer %s %s %s %s" % [@y, @x, @height, @width]
		#LOG.debug "content : #{@content}" 
		super 1000,@width
		#@input = @input.read if @input.is_a? File
		case @content
			when String
				#fork do 
				@content = understand @content 
				@raw ||= true
				@delimiter ||= ""
				#end
			#when Command
			#	@content = @content.primary			
			#	@raw = true
				#@input.entries.map{|line| Text.new line }
			#when Enumerable
			#	@content = @input
			#	@delimiter = $/
		end
		
		work
		refresh 0,0, @y, @x, @y+@height, @x+@width
	end
	def understand this#, log=false
		result = []
		if this.start_with? "__LOG" #log #@type == :log
#			@raw = false
#			@delimiter = $/
			for lines in this.lines
				for line in lines.split "|"
					command = Command.new( line )
					#LOG.debug command
					result << command.items.first if command.items
					#result << command if command.sequence
				end
			end
		end
		
		begin
		#shapes = /(?<Host>(\w+:\/\/)?(\S+\.)*(\S+\.(?:gg|de|com|org|net))(\S+)*\s)|(?<Entry>\W(\/\w+)+)|(?<Host>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/
		#shapes = /((?<Protocol>\w+:\/\/)?(?<Subdomain>\w+\.)*(?<Domain>\w+\.(?:gg|de|com|org|net))[w\/\.]+)*\s)|()/
		
#		shapes = /(?<Host>(\w+:\/\/)?([\w\.-]+\.(?:gg|de|com|org|net))|(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})([\w\/]+)*\s)?|\W(?<Entry>(\/\w+)+)/
		shapes = /\W(?<Entry>(\/[[:alnum:]]+)+)\W/
		match = shapes.match this
			if match 
		#			LOG.debug match#.post_match
				text = match.pre_match
				item = match.to_h.select{|k,v| v}
#					LOG.debug item#match#.post_match
				result << eval( item.keys.first + #if item
					".new '#{item.values.first}'" )
			else					
				text = this #word )
				
			end
			result << text.lines.map{ |line| Text.new( line ) } if @raw
			#LOG.debug result#this[0..20]				
		end while match && this = match.post_match
		
		result.flatten #@content = result 
	end
	def index; $world.index self; end
	def focus?; $focus == index; end
	def list?; @delimiter == $/; end
	def paging?; @content.size > @height and @height > 2; end
	def pageup?; @page > 0 and paging?; end
	#def pagedown?; @pagedown && paging?; end
	def pagedown?; view[-1] != @content[-1] and paging?; end
	#def pagedown?; @start < @content[-1].y-@height; end
	#def oneline?; @height < 3; end
	def page direction
		#@start += direction * (@height - 2)
		@page += direction if (direction==NEXT ? pagedown? : pageup?)
	end
	def add (item);	@content << item;work; end
	def << (object) 		
		#LOG.debug " << :#{object}"
		$world = $world[0..index] if index
		@content.unshift(object).flatten!
		@content.uniq! {|item| item.type + item.name }
		@file.write @content.to_yaml if @file
		work
	end

	def view 
		if paging? && !$filter.empty? && focus?
			#LOG.debug "#{$filter} > "
			return @content.select{|i| i.name.downcase.index($filter)}
			#[@start..@start+height-2]
		elsif list?
			#
			#return @content[@pages[@page]..-1]
			return @content[0..stop]
			#result = @content.select{|item|
				#item.y.between? @start, @start+height-2 }
		else
			return @content
		end
	end	
	def start; @page*@height;end
	def stop; (@page+1)*@height;end
	def update
		if height > 2 #list?
			draw ("v" * width), y:stop, highlight:focus? if 
				pagedown?
			draw ("^" * width), y:start, highlight:focus? if 
				pageup?
			draw (" " * width), y:stop, highlight:focus? unless 
				paging?
		end
		refresh start,0, @y, @x, @y+@height, @x+@width#right,bottom
	end	
	def work
		clear 
		setpos 0,0
		draw @prefix if @prefix
		LOG.debug " > #{self}"
		#@pageup = false if view[0] == @content[0]
		#draw $/ if not list? && curx + item.width > width #&& item.width < width
			#image = item.image #@raw #list? #self, @selection				
		for item in @content #view
			draw @delimiter if @delimiter and curx > 0  
			item.x,item.y = curx,cury
			draw item.type.colored :dark unless @raw
			#image=image[0..width-curx-1].colored(image.color)if list?
			draw ((item.has?(:@path) and @raw)? 
				item.path : item.name).colored(item.color), 
				selection:(@selection and focus?)
			draw " " + item.description[curx..@width-curx].colored(
				:bright), selection:(@selection and focus?) if 
					item.has?(:@description) and @width > LIMIT and @height > 1
		end
		#box '|', '-' 
		update
	end
	def trim
		clear
		@width = LIMIT
		update
		#resize @height, LIMIT #unless self == $world.last
	end
	def action id=KEY_TAB, x=left,y=top
		x -= left; y -= top		
		if self == COMMAND
			LOG.debug "command :#{@content}"
			#results = Command.new( @content.dup ).execute 
			target = Command.new( @content.dup )
		elsif y==height-1 && pagedown?
			page NEXT
			return
		elsif y==0 && pageup?
			page PREVIOUS
			return
		elsif list?
			target =  @content[y+start]
			#results =  view[y+start].action
			LOG.debug "pointer :#{x}, #{y}" 			
		else
			#halt
			for item in view#[1..-1] #@content#
#				LOG.debug "previous :#{previous.x}, #{previous.y}" 
				previous ||= item
				#next unless previous #|| false
				target = previous if 
					( y == item.y and	item.y == previous.y and 
						x.between?(previous.x, item.x-1) ) or
					(y == previous.y and x >= previous.x ) or
					(y == item.y and x < item.x ) or 
					(y > previous.y and y < item.y )
#				LOG.debug "item :#{item.x}, #{item.y}" 
				previous = item
			end unless view.size == 1
			results ||= previous.action( id ) #unless results
		end
		LOG.debug "target :#{target}" 
		#target = @content[-1] unless target
			
		$stack << target unless 
			[Add, Option, Section, Text, Collection
				].include? target.class
		return unless results = target.action( id )
		$world=$world[0..2]
		for result in results
			unless result.empty?		
				LOG.debug "result: #{result}"#target #item				
				$world.last.trim #unless result.empty?		
				$world << Writer.new( 
					x:$world.last.right+MARGIN+2,
					content: result, selection:true
					#delimiter:(result.is_a? String ? '':$/) 
					) 
			
			end 
		end
		$focus=$world.size-1#$focus.cycle NEXT, 2, $world.size-1		
		$filter.clear
		work
	end
end
