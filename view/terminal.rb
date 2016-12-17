
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
KEY_RETURN = 13

class Window 

	attr_accessor :focus
	alias :left :begx
	alias :width :maxx
	alias :top :begy
	alias :height :maxy
	#alias :"<<" :addstr
	def right; left + width - 1; end
	def bottom; top + height - 1; end

	def toggle
		if @highlight = !@highlight
			attron( A_STANDOUT )
		else
			attroff( A_STANDOUT )
		end
	end
	#def paging?; end
	#def page d; end

	def draw string, args={} #letters #draw args
		#parse args
		#area = args[:area]
		#id = COLORS.keys.index( 
		attron color_pair COLORS.keys.index(string.color||:text) 
		setpos args[:y]||0 ,args[:x]||0 if args[:y] || args[:x]
		toggle if args[:highlight]
		index = string.downcase.index $filter \
			unless $filter.empty? || !args[:selection]
		if index
			$selection << [ curx+left, top+cury ]
			#/^(.{#{index}})(.{#{$filter.length}})(.*)$/
			addstr string[0..index-1] if index > 0
			toggle
			addstr string[index,$filter.length]
			toggle
			addstr string[index+$filter.length..-1]
		else
			addstr string #.color 1
		end
		toggle if args[:highlight]
		#LOG.debug " %s,%s,%s " % COLORS[args[:color]]
	end
end

def init
	init_screen
	start_color
	nonl
	#cbreak
	#noraw
	#noecho
  curs_set 0
  mousemask(ALL_MOUSE_EVENTS)
	stdscr.keypad(true)
	COLORS.each_with_index do |color,i|
		init_color i, *color[1]
		#init_color i+20, *color[1].map{ |value| value+=100 }
		#init_color i+40, *color[1].map{ |value| value-=100 }
		init_pair i, i, COLOR_BLACK
  end
end	
#mousemask(BUTTON1_CLICKED|BUTTON2_CLICKED|BUTTON3_CLICKED|BUTTON4_CLICKED)
