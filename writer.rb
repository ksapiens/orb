# ORB - Omnipercipient Resource Browser
# 
# 	Writer
#
# copyright 2016 kilian reitmayr
require "helpers.rb"

class Writer < Pad #Space source #Wand staff pen pencil quill / scribe 
	attr_accessor :content, :choice
	attr_reader :height, :vertical
	include Generic
	def initialize args 
		variables_from args
		@x ||= ($world.last.right_end + 2 + MARGIN ) or LEFT
		@y ||= TOP
		@width ||= (cols-@x-1)
		@height ||= lines - TOP - BOTTOM - 2
		@choice ||= 0		
		#@page ||= 0
		@content ||= []
		#@details = []
		#@vertical = 
		#@delimiter == $/ #if @content.class == Array
		case @content
			when Command
				@output, @input, @error = Open3.popen3 @content.string
				read
				#@content = (@input.read @width).parse
			when Action
				@content = @content.run #action
			when String
				@content = @content.parse
			else
				@content = @content.to_s
		end until @content.is_a? Array
		LOG.debug "writer %s %s %s %s" % [@y, @x, @height, @width]
#		super (vertical? ? 1000:@height),(vertical? ? @width:1000) 
		super 1000,1000#@height#),(vertical? ? @width:1000) 
#		LOG.debug "writer %s %s %s %s" % [top, left, bottom, right_end]
		work 
	end
	def read length=@width; 
		@content << (@input.read length).parse #if 
		#@content.class == String
	end
	def index; $world.index self; end
	def vertical?;(list? ? !@break : @break);end
	def focus?; $focus == index; end
	def list?; @delimiter == $/; end
	def short?; @width <= LIMIT; end 
	
	def start; (@content[@choice].y - @height/2).min(0) unless @content.empty? ;end
	def stop; start + @height;end
	def update;
		refresh ( start or 0 ),0,@y,@x,@y + @height,@x + @width;
		#view.each &:detail	
	end	
	
	def pass dir; $focus=$focus.cycle dir,0,$world.size-1;nil;end
	def right; pass NEXT;work end
	def left; pass PREVIOUS;work end
	
	def move dir; @choice=@choice.cycle dir,0,view.size-1;nil;end
	def down; move NEXT; end
	def up; move PREVIOUS; end
	def forward; move NEXT * @height; end
	def backward; move PREVIOUS * @height; end
	
	def flip; @delimiter = (@delimiter == $/ ? " " : $/); end
	def less; @raw = false; end
	def more; @raw = true; end
	def long; @break = !@break; end
	
	def trim; @width = view.longest.length.max LIMIT;	work;	end	
	def view 
			return @content if $filter.empty? #or not list?#and focus?
			@content.select{|item| item.to_s.downcase[$filter]}
	end	
	def work#reveal embody prove demonstrate illustrate display evince manifest / engrave draw put assemble join combine arrange form
		return if LOADED
		clear 
		#setpos start,0
		@area ||= self
		@area.draw @prefix if @prefix
		#return 
		LOG.debug " working: #{ @content.size } items"
		#LOG.debug " working: #{ @content.join "\n" } items"
		#draw $/ if not list? && curx + item.width > width #&& item.width < width
		pos = 0 
		column = 0 if list? and @break #short?
		view.each_with_index do |item,idx|
			#next unless item
			@area.draw @delimiter if @delimiter and curx > 0  
			#item.pos = pos += item.length
			column += view[ (idx-@height)..idx
				].longest.length.max LIMIT if cury == @height and column 
			@area.draw item.symbol, x:column, color: :dark unless @raw
			@area.draw item.to_s(@full), color: item.color,selection:(
				@selection ),highlight: (idx==@choice and focus?) and 
					@selection
			item.x,item.y = curx,cury #unless list?#if @raw
			# {x:curx+left+-item.length,y:cury+top+1,width:item.length}
			#item.detail( x:curx,y:cury,height:0,area:self) unless 
			#	@break or not list? #or short? #@width <= LIMIT
		end unless @content.empty?		
		#box '|', '-' 
		#@end = cury; 
		update;	#self
	end
	
	def add item;	@content << item; work; end
	def << (item) 		
		LOG.debug " << :#{item}"
		@content.unshift(item) #.flatten!
		@content.uniq! {|item| item.long }
		item.save; work
	end
	def run; COMMAND.action; end		
	def action id=KEY_TAB, x=nil,y=nil #mouse=nil
		id=KEY_TAB if id == ONE_FINGER
		id=KEY_SHIFT_TAB if id == TWO_FINGER		
		
		return unless activity = Activity[key:id]
		#begin
		LOG.debug "action: #{activity}"#target #item				
		return activity.for(self).run if 
			methods.include? activity.long.to_sym
		#rescue NameError #NoMethodError
		
		if self == COMMAND
			return if @content.empty?
			#LOG.debug "command :#{@content}"
			target = Command.create(items: @content) 
		elsif !x and !y
			target = view[@choice]
#		elsif y==bottom-1 and x == width-1 and pagedown?
#			page NEXT; return
#		elsif y==0 and x == width-1 and pageup?
#			page PREVIOUS; return
		elsif list?
			target = view[y]
#			LOG.debug "pointer :#{x}, #{y}" 			
		else
			#(list? ? y : x) += start
			#pos,point = 0, (y + start) * @width + x
			#for item in view
			#	pos += item.length
			#	(target = item;break) if item.pos > point
				#target = view.select{|item| item.pos > point }.first
			#end
			for item in view
				(target = item;break) if item.y >= y and item.x >= x
			end
#				LOG.debug "last :#{last.x}, #{last.y}" 
#				last ||= current
#				last.y -= start
#				current.y -= start
				#next unless last #|| false
#				target = last if 
#					( y == current.y and	current.y == last.y and 
#						x.between?(last.x, current.x-1) ) or
#					(y == last.y and x >= last.x ) or
#					(y == current.y and x < current.x ) or 
#					(y > last.y and y < current.y )
#				LOG.debug "current :#{current.x}, #{current.y}" 
#				last = current
#			end unless view.size == 1
			#results ||= previous.action( id ) #unless results
		end
		#if %w[ insert rename  ].include? activity.long
		#[ Add, Option, Action ].include? target.class 
		result = activity.for( target ) #if activity.is_a? Command 
		LOG.debug "target: #{target} > #{result}"
		result = result.run while result.is_a? Action
		LOG.debug "target: #{target} > #{result}" 
		if result 
			
			STACK << target #unless 
			$world=$world[0..2]		
			$filter.clear
			
			trim #unless result.empty?		
			ENV["COLUMNS"] = (cols - right_end - 2 ).to_s
			$world << Writer.new( content: result, delimiter:$/, 
				selection:true	) 
			$focus = 3#$world.last.index #+ 1
		end
	end
end
