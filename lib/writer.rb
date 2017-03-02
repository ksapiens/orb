# ORB - Omnipercipient Resource Browser
# 
# 	Writer
#
# copyright 2017 kilian reitmayr

class Writer < Pad #Space source #Wand staff pen pencil quill / scribe 
	attr_accessor :content, :choice
	attr_reader :height#, :vertical
	include Generic
	def initialize args 
		variables_from args
		@x ||= ($world.last.right_end + 1 + MARGIN ) #or LEFT
		@y ||= TOP
		@width ||= (cols-@x-1)
		@height ||= lines - TOP - BOTTOM - 2
		@choice ||= 0		
		@content ||= []
		@delimiter ||= $/ if @content.class == Array
		case @content
			when Command
				@output, @input, @error = Open3.popen3 @content.string
				@break,@raw = true,true
				@content = []; 
				#fork{	
				read until @input.eof? #} 
			when Action
				@content = @content.run #action
			when String
				@content = @content.parse
				@break,@raw = true,true
			else
				@content = @content.to_s
		end until @content.is_a? Array
		LOG.debug "writer %s %s %s %s" % [@y, @x, @height, @width]
		if vertical?
			super 1000,@width
		else 
			super @height+1,1000
		end
		#super 1000,1000#@height#),(vertical? ? @width:1000) 
#	LOG.debug "pad %s %s %s %s" % [top, left_end, height, width]
#LOG.debug "pad %s %s %s %s" % [top, left_end, bottom, right_end]
	work 
	end
	def read length=1000 #@width
		#@content += (@input.read length).parse
		@content += @input.read.parse 		
	end
	def index; $world.index self; end
	def vertical?;(list? ? !@break : @break);end
	def focus?; $focus == index; end
	def list?; @delimiter == $/; end
	def short?; @width <= LIMIT; end 
	
	def pass dir; $focus=$focus.cycle dir,0,$world.size-1;nil;end
	def right; pass NEXT;work end
	def left; pass PREVIOUS;work end
	
	def move dir; @choice=@choice.cycle dir,0,view.size-1;nil;end
	def down; move NEXT; end
	def up; move PREVIOUS; end
	def forward; #move NEXT * @height; 
		@choice = (index_at view[@choice].x,view[@choice].y + 
			@height ).max( view.size - 1) or view.size-1; end
	def backward; #move PREVIOUS * @height; 
		@choice = (index_at view[@choice].x,view[@choice].y -
			@height ).min(0); end
	
	def flip; @delimiter = (@delimiter == $/ ? " " : $/); end
	def less; @raw,@delimiter = false,$/; end
	def more; @raw,@delimiter = true,''; end
	def long; @break = !@break; end
	
	def start; (@content[@choice].y - @height/2).min(0) unless @content.empty? ;end
	def stop; start + @height;end
	def update;
		refresh ( start or 0 ),0,@y,@x,@y + @height,@x + @width;
		#view.each &:detail	
	end	
	def backspace; setpos cury,curx-1; delch;update; end
	def trim; @width = view.longest.length.max LIMIT;	work;	end	
	def view 
		result = @raw ? @content : 
			@content.reject{|item| item.is_a? Text} 
		return result if $filter.empty? or not focus?
		result.select{|item| (item.to_s + 
			item.description).downcase[$filter]}
	end	
	def work#fill  reveal embody prove demonstrate illustrate display evince manifest / engrave draw put assemble join combine arrange form
		return if LOADED
		self.clear 
		#setpos start,0
		@area ||= self
		@area.draw @prefix if @prefix
		LOG.debug " working: #{ @content.size } items"
		#LOG.debug " working: #{ @content.join "\n" } "
		#draw $/ if not list? && curx + item.width > width #&& item.width < width
		column = 0 if list? and @break #short?
		view.each_with_index do |item,idx|
			#next unless item
			#LOG.debug " draw #{ item }"
			@area.draw @delimiter if @delimiter and curx > 0  
			if cury == @height and column 
				column += view[ (idx-@height)..idx
					].longest.length.max LIMIT 
				setpos 0,column
			end
			
			@area.draw item.symbol, x:column, color: :dark unless @raw
			@area.draw (@raw ? item.long : item.to_s)[0..@width-curx-2],				color:item.color,	selection:(@selection),highlight:(
				idx==@choice and focus?)
			@area.draw " < "+item.description[0..@width-curx-4], 
				color: :bright unless curx > @width-2 or 
					@raw or column or short? or not list?
			item.x,item.y = curx,cury #unless list?#if @raw
			
			# {x:curx+left+-item.length,y:cury+top+1,width:item.length}
			#item.detail( x:curx,y:cury,height:0,area:self) unless 
			#	@break or not list? #or short? #@width <= LIMIT
		end #unless @content.empty?
		#box '|', '-' 
		update;	#self
	end
	
	def add item; LOG.debug " add :#{item.inspect}";@content << item; work; end
	def << (item) 		
		LOG.debug " << :#{item}"
		@content.unshift(item.stack) #.flatten!
		@content.uniq! {|item| item.long }
		@choice = 0
	end
	def index_at x,y
		view.each_with_index{ |item, index|
			return index if item.y >= y and item.x >= x }
		return view.size-1
	end
	def action activity=nil, x=nil,y=nil #mouse=nil
		LOG.debug "action: #{activity}"#target #item				
		return activity.for(self).run if (activity.is_a? Action and
			methods.include? activity.long.to_sym) 
			
		if self == COMMAND and not activity
			return if @content.empty?
			LOG.debug "command :#{@content}"
			activity = Command.create(items: @content)
		elsif !x and !y
			target = view[@choice]
		else
			target = view[index_at x,y]
		end

		return target.for(self).run if ( target.is_a? Action and	
			methods.include? target.long.to_sym)
			
		result = activity.for( target ) 
			#if activity.is_a? Command 
		#LOG.debug "target: #{target} > #{result}"
		result = result.run while result.is_a? Action
		#LOG.debug "target: #{target} > #{result}" 
		COMMAND.work
		$filter.clear
		if result 
			STACK << (target or result) unless 
				[ Option, Action ].include? target.class 
			$world=$world[0..2]		
			
			STACK.trim #unless result.empty?		
			ENV["COLUMNS"] = (cols - STACK.right_end - 2 ).to_s
			$world << Writer.new( content: result,# delimiter:$/, 
				selection:true	) 
			$focus = 3#$world.last.index #+ 1
		end
	end
end
