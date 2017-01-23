
# ORB - Omnipercipient Resource Browser
# 
# 	Terminal Frontend 
#
# copyright 2016 kilian reitmayr

$LOAD_PATH << "#{File.dirname __FILE__}/.."
require 'curses'
#require "helpers.rb"
include Curses

KEY_ESC = 27
KEY_TAB = 9
KEY_SHIFT_TAB = 353
KEY_RETURN = 10

class Window 

	attr_accessor :focus #, :height
	alias :left :begx
	alias :width :maxx
	alias :top :begy
	#alias :height :maxy
	
	def right; left + @width - 1; end
	def bottom; top + @height - 1; end
	
	def mode id
		attron( id )
		yield
		attroff( id )
	end

	def draw string, args={} 
		args[:color] ||= :white
		args[:color] = COLOR.keys.index(args[:color]) if
			args[:color].is_a? Symbol
		attron color_pair args[:color]
		#COLOR.keys.index(args[:color]||:white) 
		setpos args[:y]||0 ,args[:x]||0 if args[:y] || args[:x]
		#/^(.{#{index}})(.{#{$filter.length}})(.*)$/
		match = /(#{$filter})/i.match(string) unless 
			$filter.empty? or !args[:selection]
		mode (args[:highlight] or match and $counter==$choice) ? A_STANDOUT : A_NORMAL do				
			if match	
	#			LOG.debug "term: %s,%s f: %s" % [curx,cury,$filter]
				$selection << [ curx+left, top+cury ]
				addstr match.pre_match
					mode $counter==$choice ? A_NORMAL : A_STANDOUT do 
						addstr match.to_s
					end
				$counter+=1
				#LOG.debug "counter :#{$counter}"
				addstr match.post_match
			else
				addstr string
			end
		end
	end
end

def init
	init_screen
	start_color
	#nonl
	#cbreak
	#noraw
	noecho
  curs_set 0
  mousemask(ALL_MOUSE_EVENTS)
	stdscr.keypad(true)
	COLOR.each_with_index do |color,i|
		init_color i, *color[1]
		#init_color i+20, *color[1].map{ |value| value+=100 }
		#init_color i+40, *color[1].map{ |value| value-=100 }
		init_pair i, i, COLOR_BLACK
  refresh
  end
end	
#mousemask(BUTTON1_CLICKED|BUTTON2_CLICKED|BUTTON3_CLICKED|BUTTON4_CLICKED)
