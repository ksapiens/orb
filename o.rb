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

MENU = List.new ({ content: [
	Directory.new( "/", "root" ),
	Directory.new( ENV["HOME"], "home" ),
	Directory.new( ENV["PWD"], "work"),
	#Type.new( "text", "/" ),
	#Type.new( "image", "/" ),
	#Type.new( "video", "/" ),
	Recent.new,
	Frequent.new( "frequent"),
	Directory.new( ENV["HOME"]+"/.hostlist/","web"),
	Executable.new("/usr/bin/find") ],
	x: LEFT, y: TOP, limit:LIMIT  
})

#MENU = List.new ({ content: 
#	Psych.load( "menu.default".read ),
#	x: LEFT, y: TOP, limit:LIMIT  
#	})

HELP = Text.new( { 
	content: "help.txt".read, 
	x: MENU.right + MARGIN, y: TOP } )

COMMAND = Command.new( {
	prompt: ENV["PWD"] + "> ", input: [],
	x: LEFT, y: lines - BOTTOM } ) 

WORKSPACE = [ COMMAND, MENU, HELP ]

NEXT, PREVIOUS = 1, -1
$filter=""
$selection = []
$focus = 1

# main class
class ORB 
#	def initialize; 
  def colortest
		clear
		COLORS.each_with_index do |color,i|
			"#{color[0]} - #{color_content i}".draw \
				color: color[0], x: 5, y: i, area: Curses
		end
		getch 
	end
	def primary x, y
	#LOG.debug "x: %s y: %s" % [x, y]
		for area in WORKSPACE
			if 	x.between?( area.left, area.right ) && 
					y.between?( area.top, area.bottom )
				area.primary x, y 
				break
			end
		end
		cycle NEXT
	end
	def cycle direction
		WORKSPACE[$focus].focus = false
		LOG.debug WORKSPACE.size#-1 #$focus
		$focus += direction
		$focus = 0 if $focus > WORKSPACE.size-1
		$focus = WORKSPACE.size-1 if $focus < 0
		#cycle direction unless WORKSPACE[$focus].paging?
		WORKSPACE[$focus].focus = true
	end
	def run
		loop do
			clear
			refresh
			WORKSPACE.each( &:draw )
    	input = getch #Event.poll 
			LOG.debug input #$filter
    	case input
    		when KEY_MOUSE
    			mouse = getmouse
    			primary mouse.x, mouse.y
				when KEY_ESC || KEY_EXIT
        	exit
				when KEY_F12
					colortest
				when KEY_BACKSPACE
					$filter.chop!
				when KEY_NPAGE
					WORKSPACE[$focus].page NEXT
				when KEY_PPAGE
					WORKSPACE[$focus].page PREVIOUS
				when KEY_RIGHT
					cycle NEXT					
				when KEY_LEFT
					cycle PREVIOUS
				when KEY_TAB
					$filter.clear
					primary *$selection.first
        when String
					$filter = "" if $selection.empty?        	
        	$selection.clear
        	$filter += input
        	
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
