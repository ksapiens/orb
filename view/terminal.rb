# 	 ORB - Omnipercipient Resource Browser, Terminal Frontend 
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

$LOAD_PATH << "#{File.dirname __FILE__}/.."
require 'curses'
#require "helpers.rb"
include Curses

KEY_ESC = 27
KEY_TAB = 9
KEY_SHIFT_TAB = 353
KEY_RETURN = 13
KEY_CTRL_SPACE = 0
KEY_SPACE = " "
ONE_FINGER = 4
TWO_FINGER = 16384

class Window 

	#attr_accessor :x, :y#, :width, :height #focus #, :height
	#alias :left_end :begx
	#alias :width :maxx
	#alias :top :begy
	#alias :height :maxy
	
	def top; @y; end
	def left_end; @x; end
	def right_end; @x + @width ; end
	def bottom; @y + @height ; end
	
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
		setpos args[:y]||cury ,args[:x]||curx if args[:y] || args[:x]
		#/^(.{#{index}})(.{#{$filter.length}})(.*)$/
		match = /(#{$filter})/i.match(string) if not $filter.empty?
#			args[:selection] and 
		mode (args[:highlight]) ? A_STANDOUT : A_NORMAL do				
			if match	
	#			LOG.debug "term: %s,%s f: %s" % [curx,cury,$filter]
				#$selection << [ curx+left, top+cury ]
				addstr match.pre_match
#				mode A_STANDOUT do 
				mode (args[:highlight]) ?  A_NORMAL : A_STANDOUT do
					addstr match.to_s
				end
				#$counter+=1
				#LOG.debug "counter :#{$counter}"
				addstr match.post_match
			else
				addstr string
			end
		end
	end
end

def init
	`tabs 2`
	init_screen
	start_color
	nonl
	#cbreak
	raw
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
