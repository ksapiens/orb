require 'curses'
include Curses

class Area < Window 
end

class Window
	alias :left :begx
	alias :right :maxx
	alias :top :begy
	alias :bottom :maxy
end

class String
	def draw color = :default, brightness=0, x, y, win
		win.setpos y ,x
#		win.attron( color_pair(COLORS.keys.index(color))|A_BOLD )
		id = COLORS.keys.index(color)
		UILOG.debug " %s,%s,%s " % COLORS[color]
		#COLORS[color].map!{ |value| value+=brightness } if brightness>0
		win.attron( color_pair(id)  )
		win.addstr self; end; end

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
		#init_pair i, i, COLOR_BLACK			
  end; 
end	
#mousemask(BUTTON1_CLICKED|BUTTON2_CLICKED|BUTTON3_CLICKED|BUTTON4_CLICKED)
