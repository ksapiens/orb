# ORB - Omnipercipient Resource Browser
# 
# 	Writer
#
# copyright 2016 kilian reitmayr
require "helpers.rb"

class Writer < Pad #Window #
	attr_accessor :content, :page, :choice
	attr_reader :height
	include Generic
	def initialize args 
		variables_from args
		@x ||= ($world.last.right + 2 + MARGIN ) or LEFT
		@y ||= TOP
		@width ||= (cols-@x-1)
		@height ||= lines - TOP - BOTTOM - 2
		@choice ||= 0		
		@page ||= 0
		@content ||= []
		@delimiter ||= $/ if @content.class == Array
		@content = @content.parse if raw?
		LOG.debug "writer %s %s %s %s" % [@y, @x, @height, @width]
		super 1000,@raw ? @width : 1000
		work 
	end
	def pass dir; $focus.cycle dir, 2, $world.size-1; end
	def index; $world.index self; end
	def focus?; $focus == index; end
	def list?; @delimiter == $/; end
	def raw?; !@delimiter; end
	def paging?; view.size > @height and @height > 2; end
	def pageup?; @page > 0 and paging?; end
	def pagedown?; stop < @end; end
	def move direction
		@choice = @choice.cycle direction, 0, view.size-1
		@page += NEXT if @choice > stop
		@page += PREVIOUS if @choice < start
		#work
	end
	def view 
			unless $filter.empty? #and focus?
				return @content.select{|i| 
					i.to_s.downcase.index($filter)}
			else
				return @content
			end if list?	
		@content
	end	
	def start; @page*@height;end
	def stop; (@page+1)*@height;end
	def update
		if @height > 2 #list?
			common={y:stop,x:@width,highlight:focus?}
			draw "v", common									if pagedown?
			draw "^", common.merge( y:start )	if pageup?
			draw " ", common 							unless paging?
		end
		refresh start,0, @y, @x, @y+@height, @x+@width#right,bottom
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
				draw item.to_s, color: item.color,
					#selection:(@selection ), 
					highlight: (idx==@choice) and @selection
				draw (" "+item.more),
					color: :bright if	list? and @width > LIMIT
			#end
		end
		@end = cury
		#box '|', '-' 
		update
		self
	end
	#def space; 0..(list? ? @width-curx-2 : -1); end
	def trim
		#items = view + [" "," "]
		@width = view.longest.length.max LIMIT 
		work
	end	
	def add item;	@content << item;work; end
	def << (item) 		
		#LOG.debug " << :#{item}"
		@content.unshift(item) #.flatten!
		@content.uniq! {|item| item.long }
		item.save
		work
	end
	def action id=KEY_TAB, x=nil,y=nil #mouse=nil
		if self == COMMAND
			return if @content.empty?
			#LOG.debug "command :#{@content}"
			target = Command.create(items: @content) 
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
#				LOG.debug "last :#{last.x}, #{last.y}" 
				last ||= current
				last.y -= start
				current.y -= start
				#next unless last #|| false
				target = last if 
					( y == current.y and	current.y == last.y and 
						x.between?(last.x, current.x-1) ) or
					(y == last.y and x >= last.x ) or
					(y == current.y and x < current.x ) or 
					(y > last.y and y < current.y )
#				LOG.debug "current :#{current.x}, #{current.y}" 
				last = current
			end unless view.size == 1
			#results ||= previous.action( id ) #unless results
		end
		LOG.debug "target :#{target}" 
		STACK << target unless 
			[ Add, Option, Action ].include? target.class 
		results = target.action( id )
		return unless results.is_a? Array#Enumerable
		$world=$world[0..2]#index]		
		$filter.clear
		for result in results
			next if result.empty?
			#LOG.debug "result: #{result}"#target #item				
			$world.last.trim #unless result.empty?		
			ENV["COLUMNS"] = (cols - $world.last.right - 2 ).to_s
			$world << Writer.new( content: result, selection:true	) 
		end
		$focus = 3#$world.last.index #+ 1
	end
end
