#!/usr/bin/env ruby


# ORB - Omnipercipient Resource Browser
# 
# 
#
# copyright 2016 kilian reitmayr

$LOAD_PATH << "#{File.dirname __FILE__}/."
require './view/terminal'
require 'logger'
#require "dbmanager.rb"
require "./data/manparser.rb"

UILOG = Logger.new("ui.log")

# Helpers
class Fixnum
#	def limit min, max
#		return min if self < min
#		return max if self > max; 
#		self end; 
	def min i
		return i if self < i if i
		self; end
	def max i	
		return i if self > i if i
		self; end
end
class Hash
	def method_missing *args
		self[args.first.to_sym] || super
	end
end

# Options
class Item
	attr_reader :path, :name, :focus#, :x, :y
	def to_s; name; end
	def length
		name.length; end
	def color 
		self.class.to_s.downcase.to_sym; end
	def initialize path, name=path.split("/")[-1]
		@name, @path = name, path;	end
	def click
		system "urxvt -e xdg-open %s" % @path; end
end

class Special < Item
	def color; :special; end	
end
class Recent < Special
	def initialize n="recent"
		@name = n; end
	end	

class Frequent < Special
	def initialize n= "frequent"
		@name =n;end
	end
		
class Executable < Item
	def click 
		LAYOUT[:main] = CMDBuilder.new( self ); end 
end
class Directory < Item
	def click 
		LAYOUT[:main] = FileBrowser.new( self ); end
	def list
		return @entries if @entries	
		@entries = { directories: [], files: [] }
		
		`file -i #{@path}/*`.each_line do |line|
			next if line[/cannot open/] || line[/no read permission/]
			#UILOG.debug line		
			types = line[/:(.*);/][2..-2].split "/"
    	type = ( (%w{ directory } & types) + ["item"] ).first
    	path = line[/^.*:/][0..-2]

    	if type != "directory" && FileTest.executable?(path)
  			type = "executable";end

      entry = eval( "%s.new '%s'" % [type.capitalize, path])
    	if type == "directory"
    		@entries[:directories] << entry
    	else
    		@entries[:files] << entry
    	end
    end
    @entries
  end
end
class HostList < Directory
	def color; :host; end
end

# List: manages + renders items
class List < Area 
	attr_accessor :entries, :selected, :limit, :range
	def initialize vars #e=[], x=CONF[:margin],y=CONF[:margin]
		vars.each { |k,v| instance_variable_set "@"+k.to_s, v }
		#return unless @entries
		#limit, selected, entries = @limit, @select, @entries
		super 0,0, @y||TOP, @x||LEFT 
		@range = 0..maxy/SPACING-1#maxy
		update
		end
	#def select		
	def update x=nil, y=nil #entries
		return clear if @entries.empty?
		height =( @entries.length * SPACING ).max(lines - begy - 2)
		width=(@entries.max{ |a,b| a.length <=> b.length }.length).max @limit
		resize height, width
		move y, x if y && x
		refresh; end

	def << (object); @entries << object;	end
	def [] (index); @entries[index]; end
	def draw
		return if @entries.empty?
		clear
		box '|', '-' if $DEBUG
		@entries[@range].each_with_index do |entry, i|
			entry.name.draw entry.color,i%2*10,0,i*SPACING,self		
		#def draw x,y,win
		#entry.draw 0, i * SPACING, self # todo: bg
		end
		refresh; end

	def click x,y
		target = @entries[ (y-begy) / SPACING ]
		target.click if target;	end
end
	
# Stages	
		
class CMDBuilder #< Window
	#attr_accessor :sections
	def initialize item
		@man = ManPage.new( item.to_s)
		#@options = List.new @page.options.keys, x+m 
		@sections = List.new ({ entries: @man.page.keys, \
			selected: @man.page.keys.index( "OPTIONS" )})
		
		text_x = CONF[:main_x] + @sections.maxx + 1 
		@title = @man.page["NAME"]
		#UILOG.debug "content: %s, %s" % [@man.page.keys, text_x]
		@content = List.new( {entries: @man.page["OPTIONS"], x: text_x })
		#@content = TextWindow.new @man.page["OPTIONS"], text_x 
		#draw
	end
	def draw
		[ @sections, @content ].each( &:draw )
	end
end
class FileBrowser #< Window
	attr_accessor :filter, :choices, :results
	def initialize filter#, limit
		@filter = List.new({ entries: [filter], x: CONF[:main_x] })
		@choices = List.new({ entries: filter.list[:directories]\
			,x: CONF[:main_x]+2 ,y: @filter.maxy + 1 }) #directories
		@results = List.new({ entries: filter.list[:files]\
			,x: CONF[:main_x]+2 + @choices.maxx })#files
		update
	end
	def draw
		[ @filter, @choices, @results].each( &:draw )
	end
	def update 
		@choices.entries = @filter[-1].list[:directories]
		@results.entries = @filter[-1].list[:files]
		@filter.update
		@results.update
		@choices.update @filter.begx + 2, @filter.maxy + TOP
		#@choices.refresh
#		UILOG.debug "x: %s y: %s" % [@choices.maxx,@choices.maxy]
	end
	def click x, y
		s = SPACING
		m = TOP #CONF[:margin]
		if x > @results.begx
			# results
			@results[ (y - m) / s ].click
		else
			if y >= @choices.begy 
				# choices
				@filter << @choices[ (y - @filter.maxy - m) / s ]
			else 
				# filter
				@filter.entries = @filter[0..(( y - m ) / s)]
			end
				update
		end
	end		
end
class TextWindow < Window
	attr_reader :text
	def initialize text, x=MENU.maxx+1, y=TOP #CONF[:top]
		super 0, 0 ,y ,x
		@text = text
		#UILOG.debug "bx:%s, by:%s, mx:%s, my:%s" % [begx, begy, maxx, maxy]	
#		draw
	end
	def draw
		clear
		box '|', '-' if $DEBUG
		text.draw :default,-20,0,0,self
		refresh
	end
end
class HostBrowser < Window
	attr_reader :ip, :name, :services
	def initialize n #text, x=MENU.maxx+1, y=TOP #CONF[:top]
		super 0, 0 , 0 , 0
		@name = n
		UILOG.debug "bx:%s, by:%s, mx:%s, my:%s" % [begx, begy, maxx, maxy]	
#		draw
	end
	def draw
		clear
		box '|', '-' if $DEBUG
		#text.draw 0, 0, :default, self
		refresh
	end
end

# Globals
CONF = { 	spacing: 1,
					margin: 1,
				 	top:  1,
				 	left: 1,
				 	bottom: 1,
				 	limit: 6,				 	
					colors: {	#			R			G			B
						default:  	[ 100, 100, 100 ],						
						type: 			[ 700, 700, 300 ],
						executable: [ 700, 300, 300 ],
						item: 			[ 300, 700, 300 ],
						chardevice: [ 300, 700, 700 ],
						blockdevice:[ 700, 300, 700 ],
						special: 		[ 700, 300, 700 ],
						directory: 	[ 300, 300, 700 ],
						host: 			[ 100, 300, 700 ],
						highlight: 	[ 200, 200, 200 ] } }
CONF.each{ |k,v| eval "%s=%s" % [k.upcase, v] }#.to_s +"="+ v.to_s }
MENU = List.new ({ entries: [Directory.new( "/", "root" ),
									 	Directory.new( ENV["HOME"], "home" ),
									  Directory.new( ENV["PWD"], "work"),
									  #Type.new( "text", "/" ),
									  #Type.new( "image", "/" ),
									  #Type.new( "video", "/" ),
									  Recent.new,
									  Frequent.new( "frequent"),
									  HostList.new( ENV["HOME"]+"/.hostlist/","web"),
									  Executable.new("/usr/bin/file") ],
										x: LEFT, y: TOP, limit:LIMIT  })

 #<= devices, 
 #<= configuration, 
 #<= processes, parameters 
#<= hotplugged devices 

HELP = TextWindow.new <<H
 <= all items 
 <= user directory
 <= current working directory
 <= history of items
 <= most used items
 <= host browser
    
    Orb - Open Resource Browser
    
    a) type in the option, when highlighted, press TAB to select.
    b) move your pointer over the option and click left for default action and right for action list
    c) tap for default, twofinger tap for actions
H

CONF[:main_x] = LEFT + MENU.maxx + 1
LAYOUT = { menu: MENU,
					 main: HELP }
	 				 #main: CMDBuilder.new("file")  }

# main class
class ORB # < Window
	def initialize
		@cmd = ""
		init
	end
	  
  def colortest
		clear
		COLORS.each_with_index do |color,i|
			"#{color[0]} - #{color_content i}".draw color[0],-20,5,i,Curses
			#refresh; 
			end; end
		
	def run
		loop do
			clear
			refresh
			#colortest
			LAYOUT.values.each( &:draw )
    	input = getch #Event.poll 
			refresh  
    	case input
    		when KEY_MOUSE
    			mouse = getmouse
					#UILOG.debug "x: %s y: %s SESSION: %s" % [mouse.x, mouse.y, SESSION.length]
					if mouse.x <= LAYOUT[:menu].maxx + CONF[:margin]
						 LAYOUT[:menu].click mouse.x, mouse.y
					else
						 LAYOUT[:main].click mouse.x, mouse.y
					end	
				when KEY_EXIT
        	exit
				when KEY_F12
					colortest
        else
        	@cmd += input
        	UILOG.debug @cmd
    	end
    end
  end

begin
		ORB.new.run if __FILE__ == $0
end
ensure
	use_default_colors()
  close_screen
end
