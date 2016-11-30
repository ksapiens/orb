#!/usr/bin/env ruby

# ORB - Omnipercipient Resource Browser
# 
# 	Launcher
#
# copyright 2016 kilian reitmayr

$LOAD_PATH << "#{File.dirname __FILE__}/."
require 'logger'
require 'yaml'

require 'view/terminal'
require "helpers.rb"
require "manual.rb"
require "entities.rb"
require "areas.rb"

LOG = Logger.new("orb.log")
#$DEBUG = true

eval "config.default".read

init

MENU = List.new ({ content: 
	Psych.load( "menu.default".read ),
	x: LEFT, y: TOP, limit:LIMIT  
	})

HELP = Text.new( { 
	content: "help.txt".read, 
	x: MENU.right + MARGIN, y: TOP } )

COMMAND = Command.new( {
	prompt: ENV["PWD"] + "> ", input: [],
	x: LEFT, y: lines - BOTTOM } ) 

WORKSPACE = [ COMMAND, MENU, HELP ]

# main class
class ORB 

  def colortest
		clear
		COLORS.each_with_index do |color,i|
			"#{color[0]} - #{color_content i}".draw color[0],5,i,Curses
		end
		input = getch 
	end
	def run
		loop do
			clear
			refresh
			WORKSPACE.each( &:draw )
			#COMMAND.draw
    	input = getch #Event.poll 
			#refresh  
    	case input
    		when KEY_MOUSE
    			mouse = getmouse
    			#COMMAND.primary if mouse.y == lines-BOTTOM
					LOG.debug "x: %s y: %s" % [mouse.x, mouse.y]
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
        	#@cmd += input
        	#LOG.debug @cmd
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
