
# ORB - Omnipercipient Resource Browser
# 
# 	Terminal Frontend 
#
# copyright 2016 kilian reitmayr

$LOAD_PATH << "#{File.dirname __FILE__}/.."
require 'curses'
require "helpers.rb"
include Curses

class Area < Window 
	alias :left :begx
	alias :width :maxx
	alias :top :begy
	alias :height :maxy
	def right; left + width; end
	def bottom; top + height; end
	include Generic		

	def initialize args 
		parse args 
		super @height||lines-TOP-BOTTOM, @width||0, @y||TOP, @x||LEFT
	end
	
	def draw 
		clear
		yield		
		box '|', '-' if $DEBUG
		("^" * width).draw :text,0,0,self if @pageup
		("V" * width).draw :text,0,height-1,self if @pagedown
		refresh
	end
	def page direction
		LOG.debug direction	
		scrl (direction == :down ? 1:-1) * height
		#refresh
	end
	def primary x,y
		
		if y==height-1 && @pagedown 			
			page :down
		elsif y==0 && @pageup
			page :up
		else
			return false#10#true		
		end
	end
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
	crmode
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
