#!/usr/bin/env ruby

# ORB - Omnipercipient Resource Browser
# 
# 	Launcher
#
# copyright 2016 kilian reitmayr

#$LOAD_PATH << "#{File.dirname __FILE__}/."
require './view/terminal'
require 'logger'
#require "dbmanager.rb"
require "./data/manual.rb"

LOG = Logger.new("orb.log")

# Helpers
module Generic
	def initialize args
		if args.class == Hash
			args.each { |k,v| instance_variable_set "@"+k.to_s, v }
		end			
	end
end
		
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

# Models
class Item 
#	include Generic
	attr_reader :name, :focus, :parent, :silblings, :children, :color, :actions, :default #, :x, :y
	def to_s; name; end
	def length
		name.length; end
	def color 
		classname = self.class
		until COLORS.include? classname.to_s.downcase.to_sym do
			classname = classname.superclass
		end
		classname.to_s.downcase.to_sym
	end
	def initialize name
		@name = name;	end
	
end

class Special < Item; end
class Option < Special
	attr_reader :short, :long, :description
	def primary
		@cmd += long ? long : short
	end	
end
class Section < Special
	def initialize name, content
		@content = content
		super name
	end
	def primary
		{ right: @content }
	end
end
class Recent < Special
	def initialize n="recent"
		@name = n; end
end	
class Frequent < Special
	def initialize n= "frequent"
		@name =n;end
end

class FileEntry < Item
	attr_reader :path
	def initialize path, name=path.split("/")[-1]
		@path = path
		super name;	end
	def primary
		system TERM + " xdg-open %s" % @path; end
end
class Executable < FileEntry
	def primary
		
		man = ManPage.new(name)
		#@options = List.new @page.options.keys, x+m 
		#@sections = List.new ({ 
		#	entries: @man.page.keys.map{|s| Section.new s }, \
		#	selected: @man.page.keys.index( "SYNOPSIS" )})
		#text_x = CONF[:main_x] + @sections.maxx + 1 
		#@title = @man.page["NAME"]
		{ right: man.page.map{|s,c| 
				Section.new s,c.gsub( /^[[:blank:]]+/,"")  } 
			#down:
		}
	end 
end
class Directory < FileEntry
	def primary
	 
		{ right: list[:files] }
		
		#LAYOUT[:main] = FileBrowser.new( self ); 
	end
	def list
		return @entries if @entries	
		@entries = { directories: [], files: [] }
		
		`file -i #{@path}/*`.each_line do |line|
			next if line[/cannot open/] || line[/no read permission/]
			#LOG.debug line		
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

# List: manages + renders items
class List < Area 
	attr_accessor :entries, :selected, :limit, :range
	def initialize args #e=[], x=CONF[:margin],y=CONF[:margin]
		super args #0,0, @y||TOP, @x||LEFT 
		@range = 0..bottom / SPACING-1 #maxy
		update
		end
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
			entry.to_s.draw entry.color,i%2*10,0,i*SPACING,self		
		end
		refresh; end
	def primary x,y
		target = @entries[ (y - top) / SPACING ]
		content = target.primary[:right]
		WORKSPACE[(WORKSPACE.index self)+1..-1]=nil
		WORKSPACE[-1] = (content.is_a?(String) ? Text : List).new( {
			entries: content,
			x: right+1+MARGIN, y: TOP
		} ) if target;	end
end
class Text < Area
	def draw
		clear
		box '|', '-' if $DEBUG
		@entries.draw :default,-20,0,0,self
		refresh
	end
end
class Web < Area
	attr_reader :ip, :name, :services
	def initialize n #text, x=MENU.maxx+1, y=TOP #CONF[:top]
		super 0, 0 , 0 , 0
		@name = n
		LOG.debug "bx:%s, by:%s, mx:%s, my:%s" % [begx, begy, maxx, maxy]	
#		draw
	end
	def draw
		clear
		box '|', '-' if $DEBUG
		#text.draw 0, 0, :default, self
		refresh
	end
end	
# Stages	

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
	end
	def primary x, y
		s = SPACING
		m = TOP #CONF[:margin]
		if x > @results.begx
			# results
			@results[ (y - m) / s ].primary
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


# Globals
CONF = { 	spacing: 1,
					margin: 1,
				 	top:  1,
				 	left: 1,
				 	bottom: 1,
				 	limit: 6,				 	
					term: "'urxvt -e '",
					colors: {	#			R			G			B
						default:  	[ 100, 100, 100 ],						
						type: 			[ 300, 300, 700 ],
						executable: [ 700, 300, 300 ],
						item: 			[ 300, 700, 300 ],
						chardevice: [ 300, 700, 700 ],
						blockdevice:[ 700, 300, 700 ],
						special: 		[ 700, 300, 700 ],
						directory: 	[ 700, 700, 100 ],
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
									  Directory.new( ENV["HOME"]+"/.hostlist/","web"),
									  Executable.new("/usr/bin/find") ],
										x: LEFT, y: TOP, limit:LIMIT  })

 #<= devices, 
 #<= configuration, 
 #<= processes, parameters 
#<= hotplugged devices 

HELP = Text.new( { 
	entries: (open "help.txt").read, 
	x: LEFT+LIMIT, y: TOP } )

CONF[:main_x] = LEFT + MENU.maxx + 1
#LAYOUT = { menu: MENU,
#					 main: HELP }
	 				 #main: CMDBuilder.new("file")  }
WORKSPACE = [ MENU, HELP ]


@cmd = ""
class Command
	include Generic
	#def initialize args
end

# main class
class ORB 
	def initialize
		#@cmd = ""
		init
		ENV["COLUMNS"] = (cols-LIMIT-10).to_s
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
			#LAYOUT.values.each( &:draw )
			WORKSPACE.each( &:draw )
    	input = getch #Event.poll 
			refresh  
    	case input
    		when KEY_MOUSE
    			mouse = getmouse
					#LOG.debug "x: %s y: %s SESSION: %s" % [mouse.x, mouse.y, SESSION.length]
					for area in WORKSPACE
						if 	mouse.x.between?( area.left, area.right ) && 
								mouse.y.between?( area.top, area.bottom )
							area.primary mouse.x, mouse.y 
							break
						end
					end
				when KEY_EXIT
        	exit
				when KEY_F12
					colortest
        else
        	@cmd += input
        	LOG.debug @cmd
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
