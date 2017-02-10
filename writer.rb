# ORB - Omnipercipient Resource Browser
# 
# 	Writer
#
# copyright 2016 kilian reitmayr
require "helpers.rb"

class Writer < Pad #Window #
	attr_accessor :content, :page, :choice
	include Generic
	def initialize args 
		parse args  
		@x ||= ($world.last.right + 1 + MARGIN ) or LEFT
		@y ||= TOP
		@width ||= (cols-@x)
		@height ||= lines - TOP - BOTTOM - 2
		@choice ||= 0		
		@page ||= 0
		@content ||= []
		@raw = @content.class == String
		@content = @content.parse if @raw
		@delimiter ||= $/ unless @raw
		
		LOG.debug "writer %s %s %s %s" % [@y, @x, @height, @width]
		super 1000,@width
		#fork do 
		#end
		work 
	end
	def index; $world.index self; end
	def focus?; $focus == index; end
	def list?; @delimiter == $/; end
	def paging?; @content.size > @height and @height > 2; end
	def pageup?; @page > 0 and paging?; end
	#def pagedown?; @pagedown && paging?; end
	#def pagedown?; view[-1] != @content[-1] and paging?; end
	def pagedown?; cury > stop; end
	#def oneline?; @height < 3; end
	def page direction
		#@start += direction * (@height - 2)
		@page += direction if (direction==NEXT ? pagedown? : pageup?)
		update#work
	end
	def add item;	@content << item;work; end
	def << (item) 		
		#LOG.debug " << :#{item}"
		#$world = $world[0..index] if index
		@content.unshift(item) #.flatten!
		@content.uniq! {|item| item.long }
		item.save
		work
	end
	def view 
		
			unless $filter.empty? #and focus?
			#LOG.debug "#{$filter} > "
				return @content.select{|i| 
					i.to_s.downcase.index($filter)}
			else
				return @content
			end if list?	
			#result = @content.select{|item|
				#item.y.between? @start, @start+height-2 }
		#end
		@content
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
	def step direction
		@choice = @choice.cycle direction, 0, @content.size-1
		work
	end
	def work
		return if LOADED
		clear 
		#setpos start,0
		draw @prefix if @prefix
		#LOG.debug " > #{self}"
		#draw $/ if not list? && curx + item.width > width #&& item.width < width
		view.each_with_index do |item,idx|
			draw @delimiter if @delimiter and curx > 0  
			item.x,item.y = curx,cury if @raw
				draw item.symbol, color: :dark unless @raw
				draw item.to_s[space], color: item.color,
					#selection:(@selection ), 
					highlight: (idx==@choice)
				draw (" "+item.description)[space],
					color: :bright if	@width-curx > 2 and list? and not @short 
			#end
		end
		#box '|', '-' 
		update
	end
	def space; 0..(list? ? @width-curx-2 : -1); end
	def trim
		#clear
		items = view + [" "," "]
		@width = (items.max{ |a, b| 
			a.length <=> b.length }.length+2).max LIMIT 
		@short = true
		work
		#update
		#resize @height, LIMIT #unless self == $world.last
	end
	def action id=KEY_TAB, x=nil,y=nil #mouse=nil
		if self == COMMAND
			return if @content.empty?
			#LOG.debug "command :#{@content}"
			target = Command.find_or_create(items: @content) 
		elsif !x and !y
			target = view[@choice]
		elsif y==bottom-1 and x == width-1 and pagedown?
			page NEXT; return
		elsif y==0 and x == width-1 and pageup?
			page PREVIOUS; return
		elsif list?
			target = view[y]
#			LOG.debug "pointer :#{x}, #{y}" 			
		else
			for item in view
#				LOG.debug "previous :#{previous.x}, #{previous.y}" 
				previous ||= item
				previous.y -= start
				item.y -= start
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
		STACK << target unless 
			[ Add, Option, Text, Action ].include? target.class 
		return unless results = target.action( id )
		$world=$world[0..2]#index]		
		$filter.clear
		for result in results
			next if result.empty?		
			#LOG.debug "result: #{result}"#target #item				
			$world.last.trim #unless result.empty?		
			ENV["COLUMNS"] = (cols - $world.last.right).to_s
			$world << Writer.new( content: result, selection:true	) 
		end
		$focus = $world.last.index #+ 1
	end
end
