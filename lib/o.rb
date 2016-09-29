# ORB 
VERSION = "0.2b"

require 'curses'
require 'logger'
#require "dbmanager.rb"
require "manparser.rb"
include Curses

UILOG = Logger.new("ui.log")

# Helpers
class String
	def draw color = :default, brightness=0, x, y, win
		
		win.setpos y ,x
#		win.attron( color_pair(COLORS.keys.index(color))|A_BOLD )
		id = COLORS.keys.index(color)
		UILOG.debug " %s,%s,%s " % COLORS[color]
		COLORS[color].map!{ |value| value+=brightness } if brightness>0

		UILOG.debug " %s,%s,%s " % COLORS[color]
		win.attron( color_pair(id)  )
		win.addstr self; end; end
	
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
class Window
	def left; begx; end
	def right; maxx; end
	def top; begy; end
	def bottom; maxy; end
end
# MODEL / INPUT / DATA
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
class List < Window #Pad
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
