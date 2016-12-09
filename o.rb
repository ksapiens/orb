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

NEXT, PREVIOUS = 1, -1
LOG = Logger.new("orb.log")
#$DEBUG = true
eval "config.default".read
init

STACK = List.new ({ content: [
	Directory.new( "/", "root" ),
	Directory.new( ENV["HOME"], "home" ),
	Directory.new( ENV["PWD"], "work"),
	Container.new( (ENV["PATH"].split(":")-["."]).map{ |path| 
		Directory.new path }, "apps" ),
	Executable.new("/usr/bin/find") ],
	x: LEFT#, width:1#, limit: LIMIT 
})

#MENU = List.new ({ content: 
#	Psych.load( "menu.default".read ),
#	x: LEFT, y: TOP, limit:LIMIT  
#	})

HEAD = Line.new content:[ User.new, Item.new("@"), Host.new, 
	Directory.new(ENV["PWD"],ENV["PWD"]) ],	x: LEFT, y: 0
COMMAND = Line.new content: [], prefix: "> ", delimiter: " ",
	x: LEFT, y: lines - BOTTOM
$workspace = [ HEAD, COMMAND, STACK ]

HELP = TextArea.new	content: "help.txt".read#, width:10 
#$workspace << HELP

$history = {} # apps: {}, directory: [], web: [] }
$filter=""
$selection = []
$focus = 2

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
		#LOG.debug $workspace.size #input #$filter
		for area in $workspace
			if 	x.between?( area.left, area.right ) && 
					y.between?( area.top, area.bottom )
				#LOG.debug "x: %s y: %s" % [area, y]
				area.primary x, y 
				break
			end
		end
		
		cycle NEXT
	end
	def cycle direction
		$focus = $workspace.each_with_index.map{|w,i| 
			i if w.paging? && i != $focus }.compact.first
		LOG.debug $focus
		#$focus += direction
		#$focus = 0 if $focus > $workspace.size-1
		#$focus = $workspace.size-1 if $focus < 0
		#cycle direction unless $workspace[$focus].paging?
	end
	def run
		loop do
			clear
			refresh
			$workspace.each( &:draw )
    	input = getch #Event.poll 
			
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
					$workspace[$focus].page NEXT
				when KEY_PPAGE
					$workspace[$focus].page PREVIOUS
				when KEY_RIGHT
					cycle NEXT					
				when KEY_LEFT
					cycle PREVIOUS
				when KEY_TAB
					$filter.clear
					primary *$selection.first
				when KEY_RETURN #KEY_ENTER || 
					COMMAND.primary
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
#	LOG.debug "ensure"
	use_default_colors()
  close_screen
end
