
# ORB - Omnipercipient Resource Browser
# 
# 	Terminal Frontend 
#
# copyright 2016 kilian reitmayr

$LOAD_PATH << "#{File.dirname __FILE__}/.."
require 'curses'
#require "helpers.rb"
include Curses

class Area < Window 
	alias :left :begx
	alias :width :maxx
	alias :top :begy
	alias :height :maxy
	def right; left + width - 1; end
	def bottom; top + height - 1; end

end

class String
#	def draw color = :default, brightness=0, x, y, area
	def draw color=:default, x=nil, y=nil, area
		area.setpos y ,x if x && y
#		area.attron( color_pair(COLORS.keys.index(color))|A_BOLD )

		id = COLORS.keys.index(color)
		#LOG.debug " %s,%s,%s " % COLORS[color]
		#COLORS[color].map!{ |value| value+=brightness } if brightness>0
		area.attron( color_pair(id)  )
		area.addstr self 
	end
end

def init
	init_screen
	start_color
	nonl
	cbreak
	noecho
  curs_set 0
  mousemask(ALL_MOUSE_EVENTS)
	stdscr.keypad(true)
	COLORS.each_with_index do |color,i|
		init_color i, *color[1]
		init_color i+20, *color[1].map{ |value| value+=100 }
		init_color i+40, *color[1].map{ |value| value-=100 }
		init_pair i, i, COLOR_BLACK
  end
end	
#mousemask(BUTTON1_CLICKED|BUTTON2_CLICKED|BUTTON3_CLICKED|BUTTON4_CLICKED)
