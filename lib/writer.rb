# 	 ORB - Omniscient Resource Browser, Writer
#    Copyright (C) 2018 Kilian Reitmayr <reitmayr@gmx.de>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License, version 2 
# 	 as published by the Free Software Foundation
#    
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.	
#

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
	def raw?; @raw; end
	def pass dir; $focus=$focus.cycle dir,0,$world.size-1
		$world[$focus].update; nil;end
	def step dir;@choice=@choice.cycle dir,0,view.size-1;nil;end
	def move key
		current.draw self if current
		case key
			when KEY_RIGHT 
				vertical? ? pass( NEXT ) : step( NEXT )
			when KEY_DOWN
				vertical? ? step( NEXT ) : pass( NEXT )
			when KEY_LEFT
				vertical? ? pass( PREVIOUS ) : step( PREVIOUS )
			when KEY_UP
				vertical? ? step( PREVIOUS ) : pass( PREVIOUS )
		end
		update
		#LOG.debug($focus)
		
	end
	def forward; current.draw self if current 
		@choice = (index_at current.x,current.y + 
			@height ).max( view.size - 1) or view.size-1; 
		update; end
	def backward; current.draw self if current
		@choice = (index_at current.x,current.y -
			@height ).min(0); update; end
	def flip; @delimiter = (@delimiter == $/ ? " " : $/);resize;end
	def less; @raw,@delimiter = false,$/; end
	def more; @raw,@delimiter = true,''; end
	def long; @break = !@break;resize;end
	def resize
		$world = $world[0..index]
		vertical? ? super( 1000, @width = cols-@x) : 
			super(@height, 1000);	work;	end
	def start; (current.y - @height/2).min(0) unless 
		view.empty? ;end
	def stop; start + @height;end
	def current; view[@choice]; end
	def update;
		current.draw self, true if current and focus?
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
			item.x,item.y = curx,cury #unless list?#if @raw
			@area.draw (@raw ? item.long : item.to_s)[0..@width-curx-2],				color:item.color,	selection:(@selection),highlight:(
				idx==@choice and focus?)
			@area.draw " < "+item.description[0..@width-curx-4], 
				color: :bright unless curx > @width-2 or 
					@raw or column or short? or not list?
			
			
			# {x:curx+left+-item.length,y:cury+top+1,width:item.length}
			#item.detail( x:curx,y:cury,height:0,area:self) unless 
			#	@break or not list? #or short? #@width <= LIMIT
		end #unless @content.empty?
		#box '|', '-' 
		update;	#self
	end
	# LOG.debug " add :#{item.inspect}";
	def add item; @content << item; work; end
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
			target = current
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
