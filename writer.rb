# ORB - Omnipercipient Resource Browser
# 
# 	Writer
#
# copyright 2016 kilian reitmayr
require "helpers.rb"

class Writer < Pad #Window #
	attr_accessor :content, :page
	include Generic
	def initialize args 
		parse args  
		@x ||= ($world.last.right + 1 + MARGIN ) or LEFT
		@y ||= TOP
		@width ||= (cols-@x)
		@height ||= lines - TOP - BOTTOM - 2
		@delimiter ||= $/
		@page ||= 0
		@content ||= []
		#@content = Item.all if self == STACK
		LOG.debug "writer %s %s %s %s" % [@y, @x, @height, @width]
		#LOG.debug "content : #{@content}" 
		super 1000,@width
		#@input = @input.read if @input.is_a? File
#		case @content
#			when 
				#fork do 
		@content = understand @content if @content.class == String
				#end
			#when Command
			#	@content = @content.primary			
			#	@raw = true
				#@input.entries.map{|line| Text.new line }
#		end
		work 
	end
	def understand this#, log=false
		result = []
		@raw = true
		@delimiter = nil #""
		begin
		#shapes = /(?<Host>(\w+:\/\/)?(\S+\.)*(\S+\.(?:gg|de|com|org|net))(\S+)*\s)|(?<Entry>\W(\/\w+)+)|(?<Host>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/
		#shapes = /((?<Protocol>\w+:\/\/)?(?<Subdomain>\w+\.)*(?<Domain>\w+\.(?:gg|de|com|org|net))[w\/\.]+)*\s)|()/
		
#		shapes = /(?<Host>(\w+:\/\/)?([\w\.-]+\.(?:gg|de|com|org|net))|(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})([\w\/]+)*\s)?|\W(?<Entry>(\/\w+)+)/
			shapes = /\W(?<Entry>\/[[[:alnum:]]\/]+)\W/
			match = shapes.match this
			if match 
					LOG.debug match#.post_match
				result << match.pre_match.lines.map{ |line| 
					Text.new( long:line ) } #if @raw

				item = match.to_h.select{|k,v| v}
						
				LOG.debug item#match#.post_match
				result << eval( item.keys.first + #if item
					".new long:'#{item.values.first}'" )
				this = match.post_match			
			else					
				result << Text.new( long:this ) #word )
			end
			
			#LOG.debug result#this[0..20]				
		end while match
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
		work
	end
	def add (item);	@content << item;work; end
	def << (object) 		
		#LOG.debug " << :#{object}"
		$world = $world[0..index] if index
		@content.unshift(object) #.flatten!
		@content.uniq!# {|item| item.long }
		object.save
		#@file.write @content.to_yaml if @file
		work
	end

	def view 
		
		if list?	
			
			if paging? and !$filter.empty? and focus?
			#LOG.debug "#{$filter} > "
				result = @content.select{|i| 
					i.to_s.downcase.index($filter)}
			else
				result = @content
			end
			#result = @content.select{|item|
				#item.y.between? @start, @start+height-2 }
			return result[start..stop] 
		end
		@content	
		#end
	end	
	def start; @page*@height;end
	def stop; (@page+1)*@height;end
	def update
		if @height > 2 #list?
			common={color: :white,y:stop,x:@width-1,highlight:focus?}
			draw paging? ? "v" : " ", common	if pagedown?
			draw "^", common.merge( y:start )	if pageup?
			#draw " ", common 							unless paging?
		end
		refresh start,0, @y, @x, @y+@height, @x+@width#right,bottom
	end	
	def work
		return if LOADED
		clear 
		setpos start,0
		draw @prefix if @prefix
		#LOG.debug " > #{self}"
		#@pageup = false if view[0] == @content[0]
		#draw $/ if not list? && curx + item.width > width #&& item.width < width
			#image = item.image #@raw #list? #self, @selection				
		for item in view
			draw @delimiter if @delimiter and curx > 0  
			item.x,item.y = curx,cury
			draw item.class.symbol, color: :dark unless @raw
			#image=image[0..width-curx-1].colored(image.color)if list?
			draw (@short ? item.to_s : item.long)[0..@width-curx-2], 
				color: item.class.color, selection:(@selection and focus?)
			draw " "+item.description[0..@width-curx-3],color: :bright,
				selection:(@selection and focus?) if list? and !@short #or @raw #or !item.extra
		end
		#box '|', '-' 
		update
	end
	def trim
		clear
		items = view + [" "," "]
		@width = (items.max{ |a, b| 
			a.length <=> b.length }.length+2).max LIMIT 
		@short = true
		#update
		#resize @height, LIMIT #unless self == $world.last
	end
	def action id=KEY_TAB, x=0,y=0
		if self == COMMAND
			return if @content.empty?
			#LOG.debug "command :#{@content}"
			target = Command.new( @content.dup ) 
		elsif y==bottom-1 and x == width-1 and pagedown?
			page NEXT; return
		elsif y==0 and x == width-1 and pageup?
			page PREVIOUS; return
		elsif list?
			target = view[y]
			LOG.debug "pointer :#{x}, #{y}" 			
		else
			for item in view
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
		#$stack << target unless 
		#	[Add, Option, Section, Text, Action, Collection
		#		].include? target.class 
		return unless results = target.action( id )
		$world=$world[0..index]		
		$filter.clear
		for result in results
			next if result.empty?		
			#LOG.debug "result: #{result}"#target #item				
			$world.last.trim #unless result.empty?		
			$world << Writer.new( 
				#x:$world.last.right+MARGIN+2,
				content: result, selection:true	) 
		end
		$focus = 3
#		$focus=$world.size-1
		#$focus=$focus.cycle NEXT, 2, $world.size-1					
	end
end
