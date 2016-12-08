
# ORB - Omnipercipient Resource Browser
# 
# 	Terminal Frontend 
#
# copyright 2016 kilian reitmayr

$LOAD_PATH << "#{File.dirname __FILE__}/.."
require 'curses'
require "helpers.rb"
include Curses

KEY_ESC = 27
KEY_TAB = 9
KEY_RETURN = 10

class Area < Window 
	include Generic
	attr_accessor :focus
	alias :left :begx
	alias :width :maxx
	alias :top :begy
	alias :height :maxy
	#alias :"<<" :addstr
	def right; left + width - 1; end
	def bottom; top + height - 1; end

	def initialize args 
		parse args 
		super @height||lines-TOP-BOTTOM-1, @width||0, 
			@y||TOP, @x||$workspace.last.right + MARGIN + 1
	end

	def draw &block
		clear
		#yield
		if block
			block.call 
		else
			@content.draw self
		end
		box '|', '-' if $DEBUG
		refresh
	end
	def toggle
		if @highlight = !@highlight
			attron( A_STANDOUT )
		else
			attroff( A_STANDOUT )
		end
	end
	def paging?; end
	def page d; end
end


class String
	def draw args
		area = args[:area]
		id = COLORS.keys.index(args[:color]||:default)
		area.attron color_pair(id)  
		area.setpos args[:y]||0 ,args[:x]||0 if args[:x] || args[:y]
		area.toggle if args[:highlight]
		index = self.downcase.index $filter \
			unless $filter.empty? || !args[:selection]
		if index
			$selection << [ area.curx+area.left, area.top+area.cury ]
			area.addstr self[0..index-1] if index > 0
			#LOG.debug "%s - %s" % [ area.curx + area.left, area.top + area.cury ]
			area.toggle
			area.addstr self[index,$filter.length]
			area.toggle
			area.addstr self[index+$filter.length..-1]
		else
			area.addstr self
		end
		area.toggle if args[:highlight]
		#LOG.debug " %s,%s,%s " % COLORS[color]
	end
end

def init
	init_screen
	start_color
#	nonl
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
