
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

	attr_accessor :focus #, :height
	alias :left :begx
	alias :width :maxx
	alias :top :begy
	alias :height :maxy
	
	#alias :"<<" :addstr
	
	def right; left + width - 1; end
	def bottom; top + height - 1; end
	
	def mode id
		attron( id )
		yield
		attroff( id )
	end

	#def toggle
	#	if @highlight = !@highlight
	#		attron( A_STANDOUT )
	#	else
	#		attroff( A_STANDOUT )
	#	end
	#end
	def draw string, args={} 
		attron color_pair COLORS.keys.index(string.color||:text) 
		setpos args[:y]||0 ,args[:x]||0 if args[:y] || args[:x]
		mode args[:highlight] ? A_STANDOUT : A_NORMAL do				
				#/^(.{#{index}})(.{#{$filter.length}})(.*)$/
			match = /(#{$filter})/i.match(string) unless $filter.empty? || !args[:selection]
			if match	
	#			LOG.debug "term: %s,%s f: %s" % [curx,cury,$filter]
				$selection << [ curx+left, top+cury ]
				addstr match.pre_match
				#for part in match.to_a[1..-1] 
					#if part == $filter m = 
					mode $counter==$choice ?  A_STANDOUT : A_BOLD do 
						addstr match.to_s
					end
					#toggle
				#end	
				$counter+=1
				LOG.debug "counter :#{$counter}"
				addstr match.post_match
				#toggle
				
			else
				addstr string #.color 1
			end
		end
		#toggle if args[:highlight]
		#[curx, cury]
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
	COLORS.each_with_index do |color,i|
		init_color i, *color[1]
		#init_color i+20, *color[1].map{ |value| value+=100 }
		#init_color i+40, *color[1].map{ |value| value-=100 }
		init_pair i, i, COLOR_BLACK
  refresh
  end
end	
#mousemask(BUTTON1_CLICKED|BUTTON2_CLICKED|BUTTON3_CLICKED|BUTTON4_CLICKED)
